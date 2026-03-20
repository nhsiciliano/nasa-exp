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

    @Published var selectedDate: Date = Calendar.current.date(byAdding: .day, value: -2, to: .now) ?? .now
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var isSearching = false

    var maxSelectableDate: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private let repository: EPICRepositoryProtocol

    init(repository: EPICRepositoryProtocol) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: EPICRepository())
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await search()
    }

    func search() async {
        guard !isSearching else {
            return
        }

        isSearching = true
        state = .loading

        if selectedDate > maxSelectableDate {
            selectedDate = maxSelectableDate
        }

        do {
            let entries = try await repository.fetchEntries(for: selectedDate)
            state = .loaded(entries)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }

        isSearching = false
    }
}
