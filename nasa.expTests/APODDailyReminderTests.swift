import Foundation
import XCTest
@testable import nasa_exp

@MainActor
final class APODDailyReminderTests: XCTestCase {
    private let enabledAtNine = APODDailyReminderSettings(isEnabled: true, hour: 9, minute: 0)

    // MARK: - Content

    func test_requests_fillTheWindowFromTodayAtTheChosenLocalTime() throws {
        let calendar = try makeCalendar("America/Argentina/Buenos_Aires")
        let now = try utcDate("2026-10-28T10:00:00Z") // 07:00 in Buenos Aires

        let requests = APODDailyReminder.requests(for: enabledAtNine, now: now, calendar: calendar, latest: nil)

        XCTAssertEqual(requests.count, APODDailyReminder.windowDays)
        XCTAssertEqual(requests.first?.identifier, "apod.daily.2026-10-28")
        XCTAssertEqual(requests.first?.fireDate, try utcDate("2026-10-28T12:00:00Z"))
        XCTAssertEqual(requests.last?.identifier, "apod.daily.2026-11-10")
        XCTAssertEqual(requests.first?.dateComponents.hour, 9)
        XCTAssertEqual(requests.first?.dateComponents.minute, 0)
        XCTAssertEqual(requests.first?.url, URL(string: "nasaexp://apod"))
        XCTAssertEqual(Set(requests.map(\.body)), ["Ya está publicada la imagen de hoy."])
        XCTAssertEqual(Set(requests.map(\.title)), ["Foto astronómica del día"])
    }

    func test_requests_whenTodaysTimeHasPassed_startTomorrow() throws {
        let calendar = try makeCalendar("America/Argentina/Buenos_Aires")
        let now = try utcDate("2026-10-28T13:00:00Z") // 10:00 in Buenos Aires

        let requests = APODDailyReminder.requests(for: enabledAtNine, now: now, calendar: calendar, latest: nil)

        XCTAssertEqual(requests.count, APODDailyReminder.windowDays)
        XCTAssertEqual(requests.first?.identifier, "apod.daily.2026-10-29")
    }

    func test_requests_acrossDaylightSavingEnd_keepTheLocalTime() throws {
        let calendar = try makeCalendar("Europe/Madrid") // CEST ends on 2026-10-25
        let now = try utcDate("2026-10-24T10:00:00Z")

        let requests = APODDailyReminder.requests(for: enabledAtNine, now: now, calendar: calendar, latest: nil)

        XCTAssertEqual(requests[0].fireDate, try utcDate("2026-10-25T08:00:00Z"))
        XCTAssertEqual(requests[1].fireDate, try utcDate("2026-10-26T08:00:00Z"))
        XCTAssertTrue(requests.allSatisfy { $0.dateComponents.hour == 9 })
    }

    func test_requests_titleOnlyTheDayWhoseEntryIsAlreadyOut() throws {
        // 01:00 in Buenos Aires is midnight in New York: the APOD out at that moment is still the
        // previous Eastern day's, so the 2026-10-28 notification shows the 2026-10-27 entry.
        let calendar = try makeCalendar("America/Argentina/Buenos_Aires")
        let settings = APODDailyReminderSettings(isEnabled: true, hour: 1, minute: 0)
        let latest = APODDailyReminder.LatestEntry(id: "2026-10-27", title: "Eagle Nebula Pillars")

        let requests = APODDailyReminder.requests(
            for: settings,
            now: try utcDate("2026-10-27T15:00:00Z"),
            calendar: calendar,
            latest: latest
        )

        XCTAssertEqual(requests[0].identifier, "apod.daily.2026-10-28")
        XCTAssertEqual(requests[0].body, "Eagle Nebula Pillars")
        XCTAssertEqual(requests[1].body, "Ya está publicada la imagen de hoy.")
    }

    func test_requests_beforeTheEntryOfThatDayIsOut_keepTheGenericText() throws {
        let calendar = try makeCalendar("America/Argentina/Buenos_Aires")
        // Fetched at 10:00 Buenos Aires on the 27th; the 09:00 reminder of the 28th is for the 28th's entry.
        let latest = APODDailyReminder.LatestEntry(id: "2026-10-27", title: "Eagle Nebula Pillars")

        let requests = APODDailyReminder.requests(
            for: enabledAtNine,
            now: try utcDate("2026-10-27T13:00:00Z"),
            calendar: calendar,
            latest: latest
        )

        XCTAssertEqual(requests[0].identifier, "apod.daily.2026-10-28")
        XCTAssertEqual(requests[0].body, "Ya está publicada la imagen de hoy.")
    }

    func test_latestEntryID_switchesAfterThePublicationDelay() throws {
        XCTAssertEqual(APODPublicationSchedule.latestEntryID(at: try utcDate("2026-10-28T04:10:00Z")), "2026-10-27")
        XCTAssertEqual(APODPublicationSchedule.latestEntryID(at: try utcDate("2026-10-28T04:20:00Z")), "2026-10-28")
    }

    func test_requests_whenDisabled_isEmpty() throws {
        let requests = APODDailyReminder.requests(for: .default, now: .now, calendar: try makeCalendar("UTC"), latest: nil)

        XCTAssertTrue(requests.isEmpty)
    }

    // MARK: - Rescheduling

    func test_reschedule_replacesOnlyTheReminderRequests() async throws {
        let center = FakeNotificationCenter(pending: ["apod.daily.2026-10-01", "apod.daily.2026-10-02", "other"])
        let scheduler = APODDailyReminderScheduler(center: center)

        try await scheduler.reschedule(enabledAtNine, now: try utcDate("2026-10-28T10:00:00Z"), calendar: try makeCalendar("UTC"), latest: nil)

        XCTAssertEqual(center.removed, ["apod.daily.2026-10-01", "apod.daily.2026-10-02"])
        XCTAssertEqual(center.added.count, APODDailyReminder.windowDays)
        XCTAssertEqual(center.added.first?.identifier, "apod.daily.2026-10-29")
    }

    func test_reschedule_whenDisabled_removesTheWindowWithoutAddingRequests() async throws {
        let center = FakeNotificationCenter(pending: ["apod.daily.2026-10-29", "apod.daily.2026-10-30"])
        let scheduler = APODDailyReminderScheduler(center: center)

        try await scheduler.reschedule(.default, now: .now, latest: nil)

        XCTAssertEqual(center.removed, ["apod.daily.2026-10-29", "apod.daily.2026-10-30"])
        XCTAssertTrue(center.added.isEmpty)
    }

    func test_refresh_whenEnabled_titlesTheNextReminderAndAsksForTheNextBackgroundRefresh() async throws {
        let store = makeStore()
        store.save(APODDailyReminderSettings(isEnabled: true, hour: 1, minute: 0))
        let center = FakeNotificationCenter()
        let submissions = Submissions()
        let refresher = APODDailyReminderRefresher(
            store: store,
            scheduler: APODDailyReminderScheduler(center: center),
            repository: StubAPODRepository(result: .success(makeEntry(id: "2026-10-27", title: "Eagle Nebula Pillars"))),
            submitBackgroundRefresh: { date in submissions.record(date) }
        )
        let now = try utcDate("2026-10-27T15:00:00Z")

        await refresher.refresh(now: now, calendar: try makeCalendar("America/Argentina/Buenos_Aires"))

        XCTAssertEqual(submissions.dates, [APODPublicationSchedule.nextPublication(after: now)])
        XCTAssertEqual(center.added.count, APODDailyReminder.windowDays)
        XCTAssertEqual(center.added.first?.body, "Eagle Nebula Pillars")
    }

    func test_refresh_whenFetchFails_stillSchedulesTheGenericWindow() async throws {
        let store = makeStore()
        store.save(enabledAtNine)
        let center = FakeNotificationCenter()
        let refresher = APODDailyReminderRefresher(
            store: store,
            scheduler: APODDailyReminderScheduler(center: center),
            repository: StubAPODRepository(result: .failure(NASAAPIError.offline)),
            submitBackgroundRefresh: { _ in }
        )

        await refresher.refresh(now: try utcDate("2026-10-27T15:00:00Z"), calendar: try makeCalendar("UTC"))

        XCTAssertEqual(center.added.count, APODDailyReminder.windowDays)
        XCTAssertEqual(Set(center.added.map(\.body)), ["Ya está publicada la imagen de hoy."])
    }

    func test_refresh_whenDisabled_doesNothing() async throws {
        let center = FakeNotificationCenter(pending: ["apod.daily.2026-10-29"])
        let submissions = Submissions()
        let refresher = APODDailyReminderRefresher(
            store: makeStore(),
            scheduler: APODDailyReminderScheduler(center: center),
            repository: StubAPODRepository(result: .failure(NASAAPIError.offline)),
            submitBackgroundRefresh: { date in submissions.record(date) }
        )

        await refresher.refresh()

        XCTAssertTrue(submissions.dates.isEmpty)
        XCTAssertTrue(center.added.isEmpty)
        XCTAssertTrue(center.removed.isEmpty)
    }

    // MARK: - Opt-in

    func test_enable_whenPermissionIsDenied_staysOffAndPointsToSettings() async {
        let store = makeStore()
        let center = FakeNotificationCenter(grantsAuthorization: false)
        let viewModel = DailyReminderViewModel(
            store: store,
            center: center,
            repository: StubAPODRepository(result: .failure(NASAAPIError.offline)),
            submitBackgroundRefresh: { _ in }
        )

        await viewModel.setEnabled(true)

        XCTAssertFalse(viewModel.settings.isEnabled)
        XCTAssertTrue(viewModel.isPermissionDenied)
        XCTAssertFalse(store.load().isEnabled)
        XCTAssertTrue(center.added.isEmpty)
        XCTAssertEqual(center.authorizationRequests, 1)
    }

    func test_enableThenChangeTime_savesAndReschedulesAtTheNewTime() async throws {
        let store = makeStore()
        let center = FakeNotificationCenter(grantsAuthorization: true)
        let viewModel = DailyReminderViewModel(
            store: store,
            center: center,
            repository: StubAPODRepository(result: .failure(NASAAPIError.offline)),
            submitBackgroundRefresh: { _ in }
        )

        await viewModel.setEnabled(true)
        center.pending = center.added.map(\.identifier)
        center.added = []
        let calendar = Calendar.current
        let newTime = try XCTUnwrap(calendar.date(bySettingHour: 21, minute: 30, second: 0, of: .now))
        await viewModel.setTime(newTime, calendar: calendar)

        XCTAssertEqual(store.load(), APODDailyReminderSettings(isEnabled: true, hour: 21, minute: 30))
        XCTAssertEqual(center.removed.count, APODDailyReminder.windowDays)
        XCTAssertEqual(center.added.count, APODDailyReminder.windowDays)
        XCTAssertTrue(center.added.allSatisfy { $0.dateComponents.hour == 21 && $0.dateComponents.minute == 30 })
    }

    func test_store_withoutSavedSettings_returnsDefaultOff() {
        XCTAssertEqual(makeStore().load(), .default)
        XCTAssertFalse(APODDailyReminderSettings.default.isEnabled)
    }

    // MARK: - Helpers

    private func makeStore() -> APODDailyReminderStore {
        let suiteName = "APODDailyReminderTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        addTeardownBlock {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        return APODDailyReminderStore(defaults: defaults)
    }

    private func makeCalendar(_ identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: identifier))
        return calendar
    }

    private func makeEntry(id: String, title: String) -> APODEntry {
        APODEntry(
            id: id,
            title: title,
            explanation: "",
            date: APODEntry.apiFormatter.date(from: id) ?? .now,
            copyright: nil,
            media: .unsupported,
            shareURL: nil
        )
    }

    private func utcDate(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }
}

/// Records what the reminder asks of the notification center.
private final class FakeNotificationCenter: APODReminderNotificationCenter, @unchecked Sendable {
    private let lock = NSLock()
    private let grantsAuthorization: Bool
    private var _pending: [String]
    private var _removed: [String] = []
    private var _added: [APODDailyReminder.Request] = []
    private var _authorizationRequests = 0

    init(pending: [String] = [], grantsAuthorization: Bool = true) {
        _pending = pending
        self.grantsAuthorization = grantsAuthorization
    }

    var pending: [String] {
        get { lock.withLock { _pending } }
        set { lock.withLock { _pending = newValue } }
    }

    var removed: [String] { lock.withLock { _removed } }

    var added: [APODDailyReminder.Request] {
        get { lock.withLock { _added } }
        set { lock.withLock { _added = newValue } }
    }

    var authorizationRequests: Int { lock.withLock { _authorizationRequests } }

    func requestAuthorization() async throws -> Bool {
        lock.withLock { _authorizationRequests += 1 }
        return grantsAuthorization
    }

    func isAuthorized() async -> Bool {
        grantsAuthorization
    }

    func pendingRequestIdentifiers() async -> [String] {
        pending
    }

    func removePendingRequests(withIdentifiers identifiers: [String]) {
        lock.withLock {
            _removed.append(contentsOf: identifiers)
            _pending.removeAll { identifiers.contains($0) }
        }
    }

    func add(_ request: APODDailyReminder.Request) async throws {
        lock.withLock { _added.append(request) }
    }
}

private final class Submissions: @unchecked Sendable {
    private let lock = NSLock()
    private var _dates: [Date] = []

    var dates: [Date] { lock.withLock { _dates } }

    func record(_ date: Date) {
        lock.withLock { _dates.append(date) }
    }
}

private struct StubAPODRepository: APODRepositoryProtocol {
    let result: Result<APODEntry, Error>

    func fetchToday() async throws -> APODEntry {
        try result.get()
    }

    func fetch(date: Date) async throws -> APODEntry {
        try result.get()
    }
}
