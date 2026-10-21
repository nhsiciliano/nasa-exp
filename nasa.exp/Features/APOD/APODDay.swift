import Foundation

/// APOD days follow US Eastern time. Each entry belongs to the New York calendar day it went live
/// on (science.nasa.gov publishes it at 00:05 site time), whatever the device time zone, and the
/// `yyyy-MM-dd` of that day is the entry id. `APODEntry.date` is that same day at local midnight,
/// which is what `APODViewModel` compares against its own calendar.
nonisolated enum APODDay {
    static let timeZone = TimeZone(identifier: "America/New_York") ?? .gmt

    /// The first APOD, published on 1995-06-16.
    static let firstID = "1995-06-16"

    /// Id of the APOD day that `instant` falls on.
    static func id(for instant: Date) -> String {
        easternFormatter.string(from: instant)
    }

    static func isValidID(_ id: String) -> Bool {
        calendarDayFormatter.date(from: id) != nil
    }

    /// Id `days` away from `id`, using plain calendar arithmetic (no time zone involved).
    static func id(_ id: String, offsetBy days: Int) -> String? {
        guard let day = calendarDayFormatter.date(from: id),
              let shifted = calendarDayCalendar.date(byAdding: .day, value: days, to: day) else {
            return nil
        }

        return calendarDayFormatter.string(from: shifted)
    }

    /// Whole days from `id` to `otherID`; negative when `otherID` is earlier.
    static func days(from id: String, to otherID: String) -> Int? {
        guard let start = calendarDayFormatter.date(from: id),
              let end = calendarDayFormatter.date(from: otherID) else {
            return nil
        }

        return calendarDayCalendar.dateComponents([.day], from: start, to: end).day
    }

    private static let easternFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let calendarDayCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    private static let calendarDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendarDayCalendar
        formatter.timeZone = .gmt
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
