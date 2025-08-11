import XCTest
@testable import FastingApp

@MainActor
final class DateFormattingTests: XCTestCase {
    func testHmsStringFormatting() {
        XCTAssertEqual(FastingViewModel.hmsString(from: 0), "0h 00m")
        XCTAssertEqual(FastingViewModel.hmsString(from: 3599), "0h 59m")
        XCTAssertEqual(FastingViewModel.hmsString(from: 3600), "1h 00m")
        XCTAssertEqual(FastingViewModel.hmsString(from: 3661), "1h 01m")
        XCTAssertEqual(FastingViewModel.hmsString(from: -10), "0h 00m")
    }
}
