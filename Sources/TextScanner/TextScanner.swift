import struct Foundation.URL

public struct TextScanner {
    public struct Meta {
        public let fileURL: URL?
    }
    public struct Location {
        public private(set) var line = 0
        public private(set) var column = 0
        public private(set) var offset = 0

        mutating func moveCaret(newLine isNewLine: Bool) {
            if isNewLine {
                line += 1
                column = 0
            } else {
                column += 1
            }
            offset += 1
        }
    }

    public var meta: Meta { storage.meta }
    public var loc: Location { storage.loc }
    public var isAtEnd: Bool { storage.isAtEnd }

    public init(_ input: String) {
        storage = StringReaderStorage(input)
    }

    public init(fileURL: URL, encoding: String.Encoding = .utf8, chunkSize: Int = 4096) throws {
        fatalError()
    }

    public func peek() -> Character? {
        storage.peek()
    }

    @discardableResult
    public mutating func next(where cond: (Character) -> Bool = { _ in true }) -> Character? {
        copyStorageIfShared()
        return storage.next(where: cond)
    }

    // MARK: - internal -

    class Storage {
        var meta: Meta { fatalError() }
        var loc: Location { fatalError() }
        var isAtEnd: Bool { fatalError() }

        func peek() -> Character? { fatalError() }
        func next(where cond: (Character) -> Bool) -> Character? { fatalError() }

        func copy() -> Self { fatalError() }
    }

    private(set) var storage: Storage

    private mutating func copyStorageIfShared() {
        if isKnownUniquelyReferenced(&storage) {
            return
        }
        storage = storage.copy()
    }
}
