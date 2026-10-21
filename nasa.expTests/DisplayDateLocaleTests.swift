import Foundation
import XCTest
@testable import nasa_exp

/// Display dates follow the user's locale (P1.7); these pin Spanish and English output.
final class DisplayDateLocaleTests: XCTestCase {
    private let spanish = Locale(identifier: "es_ES")
    private let english = Locale(identifier: "en_US")
    private let utc = TimeZone(identifier: "UTC")!

    func test_apodDisplayDate_usesLongStyleForLocale() {
        let entry = APODEntry(
            id: "2026-10-08",
            title: "Nebula",
            explanation: "",
            date: date(2026, 10, 8),
            copyright: nil,
            media: .unsupported,
            shareURL: nil
        )

        XCTAssertEqual(entry.displayDate(locale: spanish, timeZone: utc), "8 de octubre de 2026")
        XCTAssertEqual(entry.displayDate(locale: english, timeZone: utc), "October 8, 2026")
    }

    func test_epicDisplayDate_includesTimeForLocale() {
        let entry = EPICEntry(
            id: "20261008001303",
            title: "EPIC - 20261008001303",
            caption: "",
            date: date(2026, 10, 8, hour: 0, minute: 13),
            latitude: 0,
            longitude: 0,
            imageURL: nil,
            thumbnailURL: nil
        )

        XCTAssertEqual(entry.displayDate(locale: spanish, timeZone: utc), "8 oct 2026, 0:13")
        // English separates the time and the day period with a narrow no-break space.
        XCTAssertEqual(entry.displayDate(locale: english, timeZone: utc), "Oct 8, 2026 at 12:13\u{202F}AM")
    }

    func test_roverDisplayDate_prefixesSolForLocale() {
        let photo = makeRoverPhoto(earthDate: date(2026, 10, 20))

        XCTAssertEqual(photo.displayDate(locale: spanish, timeZone: utc), "Sol 5050 · 20 oct 2026")
        XCTAssertEqual(photo.displayDate(locale: english, timeZone: utc), "Sol 5050 · Oct 20, 2026")
    }

    func test_roverDisplayDate_withoutEarthDate_showsOnlySol() {
        let photo = makeRoverPhoto(earthDate: nil)

        XCTAssertEqual(photo.displayDate(locale: english, timeZone: utc), "Sol 5050")
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func makeRoverPhoto(earthDate: Date?) -> RoverPhoto {
        RoverPhoto(
            id: "msl-1",
            rover: .curiosity,
            sol: 5050,
            instrument: "NAV_LEFT_B",
            cameraName: "Navcam",
            cameraFullName: "Navigation Camera",
            thumbnailURL: nil,
            imageURL: nil,
            earthDate: earthDate,
            caption: "",
            credit: "NASA/JPL-Caltech"
        )
    }
}
