import Foundation
import Combine

@MainActor
final class RoversViewModel: ObservableObject {
    struct Feed {
        var photos: [RoverPhoto]
        var total: Int
        var hasMore: Bool
        var nextPage: Int
    }

    enum ViewState {
        case idle
        case loading
        case loaded(Feed)
        case failed(String)
    }

    @Published var selectedRover: RoverName = .curiosity
    @Published var selectedCamera: RoverCamera = .all
    @Published var sol: Int = 0
    @Published private(set) var latestSol: Int?
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var loadMoreErrorMessage: String?

    var availableCameras: [RoverCamera] {
        RoverCamera.options(for: selectedRover)
    }

    var canStepBackward: Bool {
        sol > 0
    }

    var canStepForward: Bool {
        guard let latestSol else {
            return true
        }
        return sol < latestSol
    }

    private let repository: RoversRepositoryProtocol
    private var searchGeneration = 0

    init(repository: RoversRepositoryProtocol) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: RoversRepository())
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await resetForSelectedRover()
    }

    /// Call after `selectedRover` changes: realigns the camera filter and jumps to the newest sol.
    func roverSelectionChanged() async {
        if !availableCameras.contains(selectedCamera) {
            selectedCamera = .all
        }

        latestSol = nil
        await resetForSelectedRover()
    }

    func jumpToLatestSol() async {
        guard let latestSol else {
            await resetForSelectedRover()
            return
        }

        sol = latestSol
        await search()
    }

    func stepSol(by delta: Int) async {
        sol = clampedSol(sol + delta)
        await search()
    }

    func search() async {
        guard !isSearching else {
            return
        }

        searchGeneration += 1
        let generation = searchGeneration
        isSearching = true
        loadMoreErrorMessage = nil
        state = .loading
        sol = clampedSol(sol)

        do {
            let page = try await repository.fetchPhotos(
                rover: selectedRover,
                sol: sol,
                camera: selectedCamera,
                page: 0
            )

            guard generation == searchGeneration else {
                return
            }

            state = .loaded(Feed(
                photos: Self.deduplicated(page.photos),
                total: page.total,
                hasMore: page.hasMore,
                nextPage: 1
            ))
        } catch {
            guard generation == searchGeneration else {
                return
            }
            state = .failed(Self.message(for: error))
        }

        isSearching = false
    }

    /// Infinite scroll hook: loads the next page once the last card shows up. After a failed page
    /// it stays quiet so the manual "Cargar más" button is the retry path.
    func loadMoreIfNeeded(after photo: RoverPhoto) async {
        guard case let .loaded(feed) = state,
              photo.id == feed.photos.last?.id,
              loadMoreErrorMessage == nil else {
            return
        }

        await loadMore()
    }

    func loadMore() async {
        guard case var .loaded(feed) = state, feed.hasMore, !isLoadingMore, !isSearching else {
            return
        }

        let generation = searchGeneration
        isLoadingMore = true
        loadMoreErrorMessage = nil

        do {
            let page = try await repository.fetchPhotos(
                rover: selectedRover,
                sol: sol,
                camera: selectedCamera,
                page: feed.nextPage
            )

            guard generation == searchGeneration else {
                isLoadingMore = false
                return
            }

            feed.photos = Self.deduplicated(feed.photos + page.photos)
            feed.total = page.total
            feed.hasMore = page.hasMore
            feed.nextPage += 1
            state = .loaded(feed)
        } catch {
            if generation == searchGeneration {
                loadMoreErrorMessage = Self.message(for: error)
            }
        }

        isLoadingMore = false
    }

    private func resetForSelectedRover() async {
        searchGeneration += 1
        let generation = searchGeneration
        state = .loading

        do {
            let latest = try await repository.fetchLatestSol(for: selectedRover)
            guard generation == searchGeneration else {
                return
            }
            latestSol = latest
            sol = latest
        } catch {
            guard generation == searchGeneration else {
                return
            }
            state = .failed(Self.message(for: error))
            return
        }

        await search()
    }

    private func clampedSol(_ value: Int) -> Int {
        let lowerBounded = max(0, value)
        guard let latestSol else {
            return lowerBounded
        }
        return min(lowerBounded, latestSol)
    }

    private static func deduplicated(_ photos: [RoverPhoto]) -> [RoverPhoto] {
        var seen = Set<String>()
        return photos.filter { seen.insert($0.id).inserted }
    }

    private static func message(for error: Error) -> String {
        (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
