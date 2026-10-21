import Foundation
import Combine

@MainActor
final class APODViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded(APODEntry)
        case failed(String)
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var selectedDate: Date
    /// Most recent APOD day: local today until NASA reports its own today, which can differ by time zone.
    @Published private(set) var latestDate: Date

    /// Day the APOD archive starts.
    let firstAvailableDate: Date

    private let repository: APODRepositoryProtocol
    private let calendar: Calendar
    private let randomDayOffset: (ClosedRange<Int>) -> Int
    private var latestRequestID = 0

    init(
        repository: APODRepositoryProtocol,
        calendar: Calendar = .current,
        now: Date = .now,
        randomDayOffset: @escaping (ClosedRange<Int>) -> Int = { Int.random(in: $0) }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.randomDayOffset = randomDayOffset

        let today = calendar.startOfDay(for: now)
        self.selectedDate = today
        self.latestDate = today
        self.firstAvailableDate = calendar.date(from: DateComponents(year: 1995, month: 6, day: 16)) ?? today
    }

    convenience init() {
        self.init(repository: APODRepository())
    }

    var isShowingLatest: Bool {
        calendar.isDate(selectedDate, inSameDayAs: latestDate)
    }

    var canGoToPreviousDay: Bool {
        selectedDate > firstAvailableDate
    }

    var canGoToNextDay: Bool {
        selectedDate < latestDate
    }

    var selectableDates: ClosedRange<Date> {
        firstAvailableDate...latestDate
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await refresh()
    }

    /// Pull to refresh: the current entry stays on screen until the new response arrives.
    func refresh() async {
        await load(date: selectedDate, keepingContent: true)
    }

    func load(date: Date, keepingContent: Bool = false) async {
        let day = min(max(calendar.startOfDay(for: date), firstAvailableDate), latestDate)

        // NASA's "today" may not exist yet for an explicit date, so the latest day always asks for today.
        if calendar.isDate(day, inSameDayAs: latestDate) {
            await loadLatest(keepingContent: keepingContent)
        } else {
            selectedDate = day
            await perform(keepingContent: keepingContent) { try await $0.fetch(date: day) }
        }
    }

    func goToPreviousDay() async {
        guard canGoToPreviousDay, let previousDay = day(byAdding: -1) else {
            return
        }

        await load(date: previousDay)
    }

    func goToNextDay() async {
        guard canGoToNextDay, let nextDay = day(byAdding: 1) else {
            return
        }

        await load(date: nextDay)
    }

    func goToRandomDate() async {
        let dayCount = calendar.dateComponents([.day], from: firstAvailableDate, to: latestDate).day ?? 0
        let offset = randomDayOffset(0...max(dayCount, 0))

        guard let randomDay = calendar.date(byAdding: .day, value: offset, to: firstAvailableDate) else {
            return
        }

        await load(date: randomDay)
    }

    private func loadLatest(keepingContent: Bool) async {
        selectedDate = latestDate

        guard let entry = await perform(keepingContent: keepingContent, { try await $0.fetchToday() }) else {
            return
        }

        let entryDay = calendar.startOfDay(for: entry.date)
        latestDate = entryDay
        selectedDate = entryDay
    }

    /// Runs a request and publishes its outcome unless a newer request started meanwhile.
    @discardableResult
    private func perform(
        keepingContent: Bool = false,
        _ request: (APODRepositoryProtocol) async throws -> APODEntry
    ) async -> APODEntry? {
        latestRequestID += 1
        let requestID = latestRequestID

        if !(keepingContent && isShowingEntry) {
            state = .loading
        }

        do {
            let entry = try await request(repository)
            guard requestID == latestRequestID else {
                return nil
            }

            state = .loaded(entry)
            return entry
        } catch {
            guard requestID == latestRequestID else {
                return nil
            }

            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
            return nil
        }
    }

    private var isShowingEntry: Bool {
        if case .loaded = state {
            return true
        }
        return false
    }

    private func day(byAdding days: Int) -> Date? {
        calendar.date(byAdding: .day, value: days, to: selectedDate)
    }
}
