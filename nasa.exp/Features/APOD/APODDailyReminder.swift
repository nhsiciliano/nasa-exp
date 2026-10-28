import Foundation

/// The user's choice for the daily APOD notification. Off until they opt in from About.
nonisolated struct APODDailyReminderSettings: Equatable {
    var isEnabled: Bool
    var hour: Int
    var minute: Int

    static let `default` = APODDailyReminderSettings(isEnabled: false, hour: 9, minute: 0)
}

/// Persists `APODDailyReminderSettings` in `UserDefaults`; the background refresh needs them
/// without the UI (declared as reason CA92.1 in `PrivacyInfo.xcprivacy`).
nonisolated struct APODDailyReminderStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> APODDailyReminderSettings {
        guard defaults.object(forKey: Key.isEnabled) != nil else {
            return .default
        }

        return APODDailyReminderSettings(
            isEnabled: defaults.bool(forKey: Key.isEnabled),
            hour: defaults.integer(forKey: Key.hour),
            minute: defaults.integer(forKey: Key.minute)
        )
    }

    func save(_ settings: APODDailyReminderSettings) {
        defaults.set(settings.isEnabled, forKey: Key.isEnabled)
        defaults.set(settings.hour, forKey: Key.hour)
        defaults.set(settings.minute, forKey: Key.minute)
    }

    private enum Key {
        static let isEnabled = "apodDailyReminder.isEnabled"
        static let hour = "apodDailyReminder.hour"
        static let minute = "apodDailyReminder.minute"
    }
}

/// Builds the pending notifications of the daily reminder. Instead of one repeating trigger,
/// each of the next `windowDays` days gets its own one-shot request, so a single day can be
/// rewritten with the real title once that entry is out, and the rest keep the generic text.
nonisolated enum APODDailyReminder {
    static let identifierPrefix = "apod.daily."
    static let windowDays = 14

    nonisolated struct Request: Equatable {
        let identifier: String
        let fireDate: Date
        /// Calendar components of `fireDate` (year to minute) for a non-repeating trigger.
        let dateComponents: DateComponents
        let title: String
        let body: String
        /// Opened when the notification is tapped, like the widget does.
        let url: URL?
    }

    /// The newest APOD the app knows about, to title the notification of its day.
    nonisolated struct LatestEntry: Equatable {
        let id: String
        let title: String
    }

    static func requests(
        for settings: APODDailyReminderSettings,
        now: Date,
        calendar: Calendar = .current,
        latest: LatestEntry?
    ) -> [Request] {
        guard settings.isEnabled else {
            return []
        }

        return fireDates(hour: settings.hour, minute: settings.minute, after: now, calendar: calendar)
            .map { request(firingAt: $0, calendar: calendar, latest: latest) }
    }

    /// The next `windowDays` occurrences of `hour:minute` in `calendar`'s time zone, from today
    /// when that time has not passed yet.
    static func fireDates(hour: Int, minute: Int, after now: Date, calendar: Calendar) -> [Date] {
        let today = calendar.startOfDay(for: now)
        let dates = (0...windowDays).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else {
                return nil
            }
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
        }

        return Array(dates.filter { $0 > now }.prefix(windowDays))
    }

    private static func request(firingAt fireDate: Date, calendar: Calendar, latest: LatestEntry?) -> Request {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let day = String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)

        // Only the day whose entry is already known gets its title; the APOD day of a local
        // morning can still be the previous Eastern day (`latestEntryID(at:)`).
        let body: String
        if let latest, latest.id == APODPublicationSchedule.latestEntryID(at: fireDate) {
            body = latest.title
        } else {
            body = String(localized: "Ya está publicada la imagen de hoy.")
        }

        return Request(
            identifier: identifierPrefix + day,
            fireDate: fireDate,
            dateComponents: components,
            title: String(localized: "Foto astronómica del día"),
            body: body,
            url: AppTab.apod.deepLinkURL
        )
    }
}
