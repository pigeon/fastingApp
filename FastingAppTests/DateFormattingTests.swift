import XCTest
@testable import FastingApp

final class DateFormattingTests: XCTestCase {
    func testShortTimeString24Hour() {
        let date = Date(timeIntervalSince1970: 0)
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        let expected = df.string(from: date)
        XCTAssertEqual(Date.shortTimeString(date, is24h: true), expected)
    }

    func testShortTimeStringLocalized() {
        let date = Date(timeIntervalSince1970: 0)
        let expected = DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
        XCTAssertEqual(Date.shortTimeString(date, is24h: false), expected)
    }
}
