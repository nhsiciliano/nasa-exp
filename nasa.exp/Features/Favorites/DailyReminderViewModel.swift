import Foundation
import Observation

/// State of the daily APOD notification section in About. Permission is asked only when the
/// user turns the reminder on, never at launch.
@Observable
final class DailyReminderViewModel {
    private(set) var settings: APODDailyReminderSettings
    /// The user said no (now or before): the toggle stays off and About points to Settings.
    private(set) var isPermissionDenied = false

    private let store: APODDailyReminderStore
    private let center: APODReminderNotificationCenter
    private let refresher: APODDailyReminderRefresher
    private let scheduler: APODDailyReminderScheduler

    init(
        store: APODDailyReminderStore = APODDailyReminderStore(),
        center: APODReminderNotificationCenter = SystemReminderNotificationCenter(),
        repository: APODRepositoryProtocol = APODRepository(),
        submitBackgroundRefresh: @escaping APODDailyReminderRefresher.BackgroundRefreshSubmitter = APODDailyReminderRefresher.submitAppRefresh
    ) {
        let scheduler = APODDailyReminderScheduler(center: center)
        self.store = store
        self.center = center
        self.scheduler = scheduler
        self.refresher = APODDailyReminderRefresher(
            store: store,
            scheduler: scheduler,
            repository: repository,
            submitBackgroundRefresh: submitBackgroundRefresh
        )
        self.settings = store.load()
    }

    /// Time of day as a `Date` today, for the time picker.
    func time(calendar: Calendar = .current, now: Date = .now) -> Date {
        calendar.date(bySettingHour: settings.hour, minute: settings.minute, second: 0, of: now) ?? now
    }

    func checkPermission() async {
        guard settings.isEnabled else {
            isPermissionDenied = false
            return
        }
        isPermissionDenied = !(await center.isAuthorized())
    }

    func setEnabled(_ isEnabled: Bool) async {
        guard isEnabled else {
            settings.isEnabled = false
            isPermissionDenied = false
            await apply()
            return
        }

        let isAuthorized: Bool
        do {
            isAuthorized = try await center.requestAuthorization()
        } catch {
            isAuthorized = false
        }

        isPermissionDenied = !isAuthorized
        settings.isEnabled = isAuthorized
        await apply()
    }

    func setTime(_ time: Date, calendar: Calendar = .current) async {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        settings.hour = components.hour ?? settings.hour
        settings.minute = components.minute ?? settings.minute
        await apply()
    }

    private func apply() async {
        store.save(settings)
        if settings.isEnabled {
            // Fetches today's entry so the next notification already carries its title.
            await refresher.refresh()
        } else {
            do {
                try await scheduler.reschedule(settings, now: .now, latest: nil)
            } catch {
                // Turning off only removes requests, which cannot fail.
            }
        }
    }
}
