import Foundation

#if !canImport(ObjectiveC)
func autoreleasepool<Result>(invoking body: () throws -> Result) rethrows -> Result {
    try body()
}
#endif

private extension TextScanner {
    static let empty = TextScanner("")
}

final class StreamReaderStorage: TextScanner.Storage {
    override var meta: TextScanner.Meta { _meta }
    override var loc: TextScanner.Location { _loc }
    override var isAtEnd: Bool {
        loadIfNeeded()
        return reader.isAtEnd && chunk.isAtEnd
    }

    private let _meta: TextScanner.Meta
    private var _loc = TextScanner.Location()

    private var reader: StreamReader
    private var chunk: TextScanner

    init(fileURL: URL, encoding: String.Encoding, chunkSize: Int) throws {
        _meta = .init(fileURL: fileURL)
        reader = try StreamReader(fileURL: fileURL, encoding: encoding, chunkSize: chunkSize)
        chunk = .empty
    }

    private init(_ storage: StreamReaderStorage) {
        _meta = storage.meta
        _loc = storage.loc
        reader = StreamReader(storage.reader)
        chunk = storage.chunk
    }

    private func loadIfNeeded() {
        guard !reader.isAtEnd && chunk.isAtEnd else { return }
        if let chunkString = reader.readChunk() {
            chunk = TextScanner(chunkString)
        } else {
            chunk = .empty
        }
    }

    override func peek() -> Character? {
        loadIfNeeded()
        return chunk.peek()
    }

    override func next(where cond: (Character) -> Bool) -> Character? {
        loadIfNeeded()
        guard let ch = chunk.next(where: cond) else { return nil }
        _loc.moveCaret(newLine: ch.isNewline)
        return ch
    }

    override func copy() -> StreamReaderStorage {
        StreamReaderStorage(self)
    }
}

// MARK: - private -
private final class StreamReader {
    private let encoding: String.Encoding
    private let chunkSize: Int
    private let delimiter: Data
    private var buffer: Data
    private var fileHandle: FileHandle
    private(set) var isAtEnd = false
    private var offset: UInt64 = 0
    private let queue: DispatchQueue

    init(fileURL: URL, encoding _encoding: String.Encoding, chunkSize _chunkSize: Int) throws {
        fileHandle = try FileHandle(forReadingFrom: fileURL)
        encoding = _encoding
        chunkSize = _chunkSize
        delimiter = "\n".data(using: encoding)!
        buffer = Data(capacity: chunkSize)
        queue = DispatchQueue(label: "TextScanner.StreamReader")
    }

    init(_ copy: StreamReader) {
        fileHandle = copy.fileHandle
        offset = copy.offset
        encoding = copy.encoding
        chunkSize = copy.chunkSize
        delimiter = copy.delimiter
        buffer = copy.buffer
        isAtEnd = copy.isAtEnd
        queue = copy.queue
    }

    func readChunk(_ consumer: Int = 5) -> String? {
        if isAtEnd || consumer <= 0 {
            isAtEnd = true
            return nil
        }

        return autoreleasepool {
            repeat {
                if let range = buffer.range(of: delimiter, options: .backwards) {
                    let subdata = buffer[..<range.upperBound]
                    let line = String(data: subdata, encoding: encoding)
                    buffer.replaceSubrange(..<range.upperBound, with: [])
                    return line ?? readChunk(consumer - 1)
                }

                let tmp: Data = queue.sync {
                    fileHandle.seek(toFileOffset: offset)
                    let data = fileHandle.readData(ofLength: chunkSize)
                    offset += UInt64(data.count)
                    return data
                }
                if tmp.isEmpty {
                    isAtEnd = true
                    return buffer.isEmpty ? nil : String(data: buffer, encoding: encoding)
                }
                buffer.append(tmp)
            } while true
        }
    }
}
