import Foundation
import XCTest
@testable import nasa_exp

/// Favorites show their date in the current language, not the one active when they were saved (P1.15).
@MainActor
final class FavoriteDisplayDateTests: XCTestCase {
    private let spanish = Locale(identifier: "es_ES")
    private let english = Locale(identifier: "en_US")
    private let utc = TimeZone(identifier: "UTC")!

    func test_apodFavorite_withOriginalDate_isFormattedForEachLocale() {
        let item = makeItem(type: .apod, subtitle: "8 de octubre de 2026", originalDate: date(2026, 10, 8))

        XCTAssertEqual(item.displayDate(locale: spanish, timeZone: utc), "8 de octubre de 2026")
        XCTAssertEqual(item.displayDate(locale: english, timeZone: utc), "October 8, 2026")
    }

    func test_epicFavorite_withOriginalDate_isFormattedForEachLocale() {
        let item = makeItem(type: .epic, subtitle: "8 oct 2026, 0:13", originalDate: date(2026, 10, 8, hour: 0, minute: 13))

        XCTAssertEqual(item.displayDate(locale: spanish, timeZone: utc), "8 oct 2026, 0:13")
        XCTAssertEqual(item.displayDate(locale: english, timeZone: utc), "Oct 8, 2026 at 12:13\u{202F}AM")
    }

    func test_roverFavorite_withOriginalDateAndSol_isFormattedForEachLocale() {
        let item = makeItem(type: .rover, subtitle: "Sol 5050 · 20 oct 2026", originalDate: date(2026, 10, 20), sol: 5050)

        XCTAssertEqual(item.displayDate(locale: spanish, timeZone: utc), "Sol 5050 · 20 oct 2026")
        XCTAssertEqual(item.displayDate(locale: english, timeZone: utc), "Sol 5050 · Oct 20, 2026")
    }

    func test_roverFavorite_savedBeforeSolField_readsSolFromStoredSubtitle() {
        let item = makeItem(type: .rover, subtitle: "Sol 4012 · 3 mar 2026", originalDate: date(2026, 3, 3))

        XCTAssertEqual(item.displayDate(locale: english, timeZone: utc), "Sol 4012 · Mar 3, 2026")
    }

    func test_favoriteWithoutOriginalDate_fallsBackToStoredSubtitle() {
        for type in [FavoriteContentType.apod, .rover, .epic] {
            let item = makeItem(type: type, subtitle: "Texto guardado", originalDate: nil)

            XCTAssertEqual(item.displayDate(locale: english, timeZone: utc), "Texto guardado", "\(type)")
        }
    }

    func test_rebuiltDetailModels_formatTheOriginalDateInsteadOfTheStoredSubtitle() {
        let apod = APODEntry(favoriteItem: makeItem(type: .apod, subtitle: "8 de octubre de 2026", originalDate: date(2026, 10, 8)))
        let epic = EPICEntry(favoriteItem: makeItem(type: .epic, subtitle: "8 oct 2026, 0:13", originalDate: date(2026, 10, 8, hour: 0, minute: 13)))
        let rover = RoverPhoto(favoriteItem: makeItem(type: .rover, subtitle: "Sol 5050 · 20 oct 2026", originalDate: date(2026, 10, 20), sol: 5050))

        XCTAssertEqual(apod.displayDate(locale: english, timeZone: utc), "October 8, 2026")
        XCTAssertEqual(epic.displayDate(locale: english, timeZone: utc), "Oct 8, 2026 at 12:13\u{202F}AM")
        XCTAssertEqual(rover.displayDate(locale: english, timeZone: utc), "Sol 5050 · Oct 20, 2026")
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    private func makeItem(
        type: FavoriteContentType,
        subtitle: String,
        originalDate: Date?,
        sol: Int? = nil
    ) -> FavoriteItem {
        FavoriteItem(
            key: "\(type.rawValue)-test",
            contentTypeRaw: type.rawValue,
            remoteID: type == .apod ? "2026-10-08" : "test",
            title: "Título",
            subtitle: subtitle,
            details: "",
            mediaURLString: "https://example.com/image.jpg",
            originalDate: originalDate,
            sol: sol
        )
    }
}
