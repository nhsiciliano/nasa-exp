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

    private let repository: APODRepositoryProtocol

    init(repository: APODRepositoryProtocol) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: APODRepository())
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await refresh()
    }

    func refresh() async {
        state = .loading

        do {
            let entry = try await repository.fetchToday()
            state = .loaded(entry)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }
    }
}
