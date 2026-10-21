import Foundation

/// When a new Astronomy Picture of the Day is expected. APOD days roll over at midnight US Eastern
/// time (`APODDay`) and science.nasa.gov publishes the new entry a few minutes later, at 00:05.
nonisolated enum APODPublicationSchedule {
    static let publicationDelay: TimeInterval = 15 * 60
    static let retryInterval: TimeInterval = 60 * 60

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = APODDay.timeZone
        return calendar
    }()

    /// When to fetch again after showing `entryID` at `now`; pass `nil` after a failed fetch.
    /// Today's entry is kept until the next one is due; a missing or stale entry is retried soon.
    static func nextRefresh(after now: Date, showing entryID: String?) -> Date {
        guard entryID == APODDay.id(for: now) else {
            return now.addingTimeInterval(retryInterval)
        }

        return nextPublication(after: now)
    }

    /// When the entry for the next US Eastern day is expected.
    static func nextPublication(after now: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: now)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            ?? startOfDay.addingTimeInterval(24 * 60 * 60)
        return nextMidnight.addingTimeInterval(publicationDelay)
    }
}
