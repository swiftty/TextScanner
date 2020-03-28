import struct Foundation.URL

final class StringReaderStorage: TextScanner.Storage {
    override var meta: TextScanner.Meta { _meta }
    override var loc: TextScanner.Location { _loc }
    override var isAtEnd: Bool { _offsetIndex == input.endIndex }

    private let _meta: TextScanner.Meta
    private var _loc = TextScanner.Location()
    private let input: String
    private var _offsetIndex: String.Index
    private var offsetIndex: String.Index? { isAtEnd ? nil : _offsetIndex }

    private init(_ storage: StringReaderStorage) {
        _meta = storage.meta
        _loc = storage.loc
        input = storage.input
        _offsetIndex = storage._offsetIndex
    }

    init(_ input: String, fileURL: URL? = nil) {
        self.input = input
        _meta = .init(fileURL: fileURL)
        _offsetIndex = input.startIndex
    }

    override func peek() -> Character? {
        guard let i = offsetIndex else { return nil }
        return input[i]
    }

    override func next(where cond: (Character) -> Bool) -> Character? {
        guard let ch = peek(), cond(ch) else { return nil }
        _offsetIndex = isAtEnd ? input.endIndex : input.index(after: _offsetIndex)
        _loc.moveCaret(newLine: ch.isNewline)
        return ch
    }

    override func copy() -> StringReaderStorage {
        StringReaderStorage(self)
    }
}
