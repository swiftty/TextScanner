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

    static var allTests = [
        ("testStringScanner", testStringScanner),
    ]
}
