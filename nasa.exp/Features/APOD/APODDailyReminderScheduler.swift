import BackgroundTasks
import Foundation
import UserNotifications

/// The parts of `UNUserNotificationCenter` the reminder uses, so tests can record them.
nonisolated protocol APODReminderNotificationCenter: Sendable {
    func requestAuthorization() async throws -> Bool
    func isAuthorized() async -> Bool
    func pendingRequestIdentifiers() async -> [String]
    func removePendingRequests(withIdentifiers identifiers: [String])
    func add(_ request: APODDailyReminder.Request) async throws
}

nonisolated struct SystemReminderNotificationCenter: APODReminderNotificationCenter {
    private var center: UNUserNotificationCenter { .current() }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func isAuthorized() async -> Bool {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    func pendingRequestIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func add(_ request: APODDailyReminder.Request) async throws {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default
        if let url = request.url {
            content.userInfo = [APODDailyReminderScheduler.urlKey: url.absoluteString]
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: request.dateComponents, repeats: false)
        try await center.add(UNNotificationRequest(identifier: request.identifier, content: content, trigger: trigger))
    }
}

/// Replaces the pending reminder notifications with the ones `APODDailyReminder` plans.
nonisolated struct APODDailyReminderScheduler {
    static let urlKey = "url"

    private let center: APODReminderNotificationCenter

    init(center: APODReminderNotificationCenter = SystemReminderNotificationCenter()) {
        self.center = center
    }

    func reschedule(
        _ settings: APODDailyReminderSettings,
        now: Date,
        calendar: Calendar = .current,
        latest: APODDailyReminder.LatestEntry?
    ) async throws {
        // Notifications that are not the reminder's (none today) are left alone.
        let previous = await center.pendingRequestIdentifiers().filter { $0.hasPrefix(APODDailyReminder.identifierPrefix) }
        center.removePendingRequests(withIdentifiers: previous)

        for request in APODDailyReminder.requests(for: settings, now: now, calendar: calendar, latest: latest) {
            try await center.add(request)
        }
    }
}

/// Keeps the reminder window filled and titled: at launch and from the background refresh,
/// which iOS runs at a time of its choosing after the next publication.
nonisolated struct APODDailyReminderRefresher {
    typealias BackgroundRefreshSubmitter = @Sendable (_ earliestBeginDate: Date) -> Void

    static var taskIdentifier: String {
        // Must match `BGTaskSchedulerPermittedIdentifiers` in Config/Info.plist.
        "\(Bundle.main.bundleIdentifier ?? "den-mobile.nasaexp").apod-refresh"
    }

    private let store: APODDailyReminderStore
    private let scheduler: APODDailyReminderScheduler
    private let repository: APODRepositoryProtocol
    private let submitBackgroundRefresh: BackgroundRefreshSubmitter

    init(
        store: APODDailyReminderStore = APODDailyReminderStore(),
        scheduler: APODDailyReminderScheduler = APODDailyReminderScheduler(),
        repository: APODRepositoryProtocol = APODRepository(),
        submitBackgroundRefresh: @escaping BackgroundRefreshSubmitter = APODDailyReminderRefresher.submitAppRefresh
    ) {
        self.store = store
        self.scheduler = scheduler
        self.repository = repository
        self.submitBackgroundRefresh = submitBackgroundRefresh
    }

    func refresh(now: Date = .now, calendar: Calendar = .current) async {
        let settings = store.load()
        guard settings.isEnabled else {
            return
        }

        submitBackgroundRefresh(APODPublicationSchedule.nextPublication(after: now))

        let latest: APODDailyReminder.LatestEntry?
        do {
            let entry = try await repository.fetchToday()
            latest = APODDailyReminder.LatestEntry(id: entry.id, title: entry.title)
        } catch {
            // The window is still extended; those days keep the generic text.
            latest = nil
        }

        do {
            try await scheduler.reschedule(settings, now: now, calendar: calendar, latest: latest)
        } catch {
            // A failed add leaves fewer days pending; the next refresh rebuilds the whole window.
        }
    }

    @Sendable
    static func submitAppRefresh(earliestBeginDate: Date) {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = earliestBeginDate
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Unavailable in the simulator and when Background App Refresh is off; the reminder
            // still fires with the generic text.
        }
    }
}
