import XCTest
@testable import TextScanner

final class TextScannerTests: XCTestCase {
    func testStringScanner() throws {
        var scanner = TextScanner("""
        12
        34
        """)
        XCTAssertEqual(scanner.isAtEnd, false)

        XCTAssertEqual(scanner.next(), "1")
        XCTAssertEqual(scanner.next(), "2")
        XCTAssertEqual(scanner.peek(), "\n")
        XCTAssertEqual(scanner.next(), "\n")
        XCTAssertEqual(scanner.next(), "3")
        XCTAssertEqual(scanner.next(), "4")

        XCTAssertEqual(scanner.isAtEnd, true)

        XCTAssertEqual(scanner.next(), nil)

        XCTAssertEqual(scanner.isAtEnd, true)
        XCTAssertEqual(scanner.loc.line, 1)
        XCTAssertEqual(scanner.loc.column, 2)
        XCTAssertEqual(scanner.loc.offset, 5)
    }

    func testEmptyFile() throws {
        let scanner = try TextScanner(fileURL: file("empty.txt"))
        XCTAssertEqual(scanner.isAtEnd, true)
    }

    func testCopyOnWrite() throws {
        var scanner = try TextScanner(fileURL: file("test_01.txt"), chunkSize: 2)
        XCTAssertEqual(scanner.next(), "1")

        var copy = scanner
        XCTAssertEqual(scanner.isAtEnd, false)
        XCTAssertEqual(scanner.peek(), "2")
        XCTAssertEqual(scanner.storage === copy.storage, true)
        XCTAssertEqual(scanner.next(), "2")
        XCTAssertEqual(scanner.storage !== copy.storage, true)
        XCTAssertEqual(copy.next(), "2")

        copy = scanner

        XCTAssertEqual(scanner.storage === copy.storage, true)
        copy.next()
        XCTAssertEqual(scanner.storage !== copy.storage, true)
    }

    static var allTests = [
        ("testStringScanner", testStringScanner),
        ("testEmptyFile", testEmptyFile),
        ("testCopyOnWrite", testCopyOnWrite)
    ]
}

private func file(_ name: String) -> URL {
    return URL(fileURLWithPath: #file)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("TextScannerTestsResources")
        .appendingPathComponent(name)
}
