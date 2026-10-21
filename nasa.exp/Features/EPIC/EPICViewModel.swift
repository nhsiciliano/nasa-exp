import Foundation
import Combine

@MainActor
final class EPICViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded([EPICEntry])
        case failed(String)
    }

    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now {
        didSet {
            scheduleSearchForSelectedDate()
        }
    }
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var isSearching = false

    var maxSelectableDate: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private let repository: EPICRepositoryProtocol
    private let searchDebounce: Duration
    private var debounceTask: Task<Void, Never>?
    private var requestedDay: Date?

    init(repository: EPICRepositoryProtocol, searchDebounce: Duration = .milliseconds(400)) {
        self.repository = repository
        self.searchDebounce = searchDebounce
    }

    convenience init() {
        self.init(repository: EPICRepository())
    }

    /// Opens on the most recent day NASA has published and moves the date picker to it.
    func loadIfNeeded() async {
        guard case .idle = state, !isSearching else {
            return
        }

        isSearching = true
        defer { isSearching = false }
        state = .loading

        do {
            let entries = try await repository.fetchLatest()
            if let latestDate = entries.first?.date {
                requestedDay = Calendar.current.startOfDay(for: latestDate)
                selectedDate = latestDate
            }
            state = .loaded(entries)
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    /// Pull to refresh: the current results stay on screen until the new response arrives.
    func refresh() async {
        await search(keepingContent: true)
    }

    func search(keepingContent: Bool = false) async {
        guard !isSearching else {
            return
        }

        debounceTask?.cancel()
        isSearching = true
        defer { isSearching = false }

        // Only the first pass repeats the date on screen; later passes follow a new date.
        var keepsContent = keepingContent

        // The date can change while a request is in flight, so keep going until the result matches it.
        repeat {
            if selectedDate > maxSelectableDate {
                selectedDate = maxSelectableDate
            }

            let day = Calendar.current.startOfDay(for: selectedDate)
            requestedDay = day

            if !(keepsContent && isShowingEntries) {
                state = .loading
            }
            keepsContent = false

            do {
                state = .loaded(try await repository.fetchEntries(for: selectedDate))
            } catch {
                state = .failed(Self.message(for: error))
            }
        } while Calendar.current.startOfDay(for: selectedDate) != requestedDay
    }

    private var isShowingEntries: Bool {
        if case .loaded = state {
            return true
        }
        return false
    }

    private func scheduleSearchForSelectedDate() {
        debounceTask?.cancel()

        guard Calendar.current.startOfDay(for: selectedDate) != requestedDay else {
            return
        }

        debounceTask = Task { [weak self, searchDebounce] in
            try? await Task.sleep(for: searchDebounce)
            guard !Task.isCancelled else {
                return
            }

            // Detached from `debounceTask` so a later date change cannot cancel a request in flight.
            Task { await self?.searchIfDateChanged() }
        }
    }

    private func searchIfDateChanged() async {
        guard Calendar.current.startOfDay(for: selectedDate) != requestedDay else {
            return
        }

        await search()
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
