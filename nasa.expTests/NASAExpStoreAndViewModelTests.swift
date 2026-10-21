import Foundation
import SwiftData
import XCTest
@testable import nasa_exp

@MainActor
final class NASAExpStoreAndViewModelTests: XCTestCase {
    func test_favoriteStore_addContainsRemove_roundTrip() throws {
        let container = try ModelContainer(
            for: FavoriteItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let draft = FavoriteDraft(
            contentType: .apod,
            remoteID: "2026-03-13",
            title: "Sample APOD",
            subtitle: "13 de marzo de 2026",
            details: "Detalles de prueba",
            mediaURL: URL(string: "https://example.com/apod.jpg")
        )

        XCTAssertFalse(FavoriteStore.contains(draft, in: context))

        FavoriteStore.add(draft, in: context)

        XCTAssertTrue(FavoriteStore.contains(draft, in: context))

        let fetched = try context.fetch(FetchDescriptor<FavoriteItem>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.key, draft.key)

        FavoriteStore.remove(draft, in: context)

        XCTAssertFalse(FavoriteStore.contains(draft, in: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<FavoriteItem>()).count, 0)
    }

    func test_favoriteModels_reconstructNativeDetailsFromStoredFavorite() {
        let apodFavorite = FavoriteItem(
            key: "apod-2026-03-13",
            contentTypeRaw: FavoriteContentType.apod.rawValue,
            remoteID: "2026-03-13",
            title: "Nebula",
            subtitle: "13 de marzo de 2026",
            details: "A bright nebula.",
            mediaURLString: "https://example.com/apod.jpg"
        )
        let roverFavorite = FavoriteItem(
            key: "rover-42",
            contentTypeRaw: FavoriteContentType.rover.rawValue,
            remoteID: "42",
            title: "Curiosity - NAVCAM",
            subtitle: "Sol 1000 · 30 may 2015",
            details: "Navigation Camera",
            mediaURLString: "https://example.com/rover.jpg"
        )
        let epicFavorite = FavoriteItem(
            key: "epic-202603130001",
            contentTypeRaw: FavoriteContentType.epic.rawValue,
            remoteID: "202603130001",
            title: "EPIC - 202603130001",
            subtitle: "13 mar 2026",
            details: "Earth from orbit",
            mediaURLString: "https://example.com/epic.png"
        )

        let apodEntry = APODEntry(favoriteItem: apodFavorite)
        let roverPhoto = RoverPhoto(favoriteItem: roverFavorite)
        let epicEntry = EPICEntry(favoriteItem: epicFavorite)

        XCTAssertEqual(apodEntry.id, "2026-03-13")
        XCTAssertEqual(roverPhoto.roverName, "Curiosity")
        XCTAssertEqual(roverPhoto.rover, .curiosity)
        XCTAssertEqual(roverPhoto.cameraName, "NAVCAM")
        XCTAssertEqual(roverPhoto.sol, 1000)
        XCTAssertEqual(roverPhoto.displayDate, "Sol 1000 · 30 may 2015")
        XCTAssertEqual(epicEntry.id, "202603130001")
        XCTAssertEqual(epicEntry.title, "EPIC - 202603130001")
    }

    func test_apodViewModel_refresh_setsLoadedStateOnSuccess() async {
        let expected = APODEntry(dto: APODResponseDTO(
            title: "Nebula",
            explanation: "A bright nebula.",
            date: "2026-03-13",
            mediaType: "image",
            url: "https://example.com/apod.jpg",
            hdurl: nil,
            copyright: nil
        ))
        let viewModel = APODViewModel(repository: MockAPODRepository(result: .success(expected)))

        await viewModel.refresh()

        guard case let .loaded(entry) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(entry.id, expected.id)
        XCTAssertEqual(entry.title, expected.title)
    }

    func test_apodViewModel_refresh_setsFailedStateOnError() async {
        let viewModel = APODViewModel(repository: MockAPODRepository(result: .failure(MockError.sample)))

        await viewModel.refresh()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }

        XCTAssertTrue(message.contains("Sample failure"))
    }

    func test_roversViewModel_loadIfNeeded_jumpsToLatestSolAndLoadsFirstPage() async {
        let repository = MockRoversRepository(latestSol: 5050, pages: [
            0: RoverPhotoPage(photos: makeRoverPhotos(range: 0..<40), total: 70, hasMore: true),
            1: RoverPhotoPage(photos: makeRoverPhotos(range: 40..<70), total: 70, hasMore: false)
        ])
        let viewModel = RoversViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.latestSol, 5050)
        XCTAssertEqual(viewModel.sol, 5050)
        XCTAssertEqual(repository.requestedSols, [5050])

        guard case let .loaded(feed) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(feed.photos.count, 40)
        XCTAssertEqual(feed.total, 70)
        XCTAssertTrue(feed.hasMore)
        XCTAssertFalse(viewModel.isSearching)

        await viewModel.loadMore()

        guard case let .loaded(expanded) = viewModel.state else {
            return XCTFail("Expected loaded state after loadMore")
        }

        XCTAssertEqual(expanded.photos.count, 70)
        XCTAssertFalse(expanded.hasMore)
        XCTAssertEqual(repository.requestedPages, [0, 1])
    }

    func test_roversViewModel_stepSol_clampsToLatestSol() async {
        let repository = MockRoversRepository(latestSol: 10, pages: [
            0: RoverPhotoPage(photos: [], total: 0, hasMore: false)
        ])
        let viewModel = RoversViewModel(repository: repository)

        await viewModel.loadIfNeeded()
        await viewModel.stepSol(by: 5)

        XCTAssertEqual(viewModel.sol, 10)

        viewModel.sol = -3
        await viewModel.search()

        XCTAssertEqual(viewModel.sol, 0)
    }

    func test_roversViewModel_search_setsFailedStateOnError() async {
        let repository = MockRoversRepository(latestSol: 10, pages: [:], error: MockError.sample)
        let viewModel = RoversViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }

        XCTAssertTrue(message.contains("Sample failure"))
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_epicViewModel_search_setsFailedStateOnError() async {
        let viewModel = EPICViewModel(repository: MockEPICRepository(result: .failure(MockError.sample)))

        await viewModel.search()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }

        XCTAssertTrue(message.contains("Sample failure"))
        XCTAssertFalse(viewModel.isSearching)
    }
}

private struct MockAPODRepository: APODRepositoryProtocol {
    let result: Result<APODEntry, Error>

    func fetchToday() async throws -> APODEntry {
        try result.get()
    }

    func fetch(date: Date) async throws -> APODEntry {
        try result.get()
    }
}

private final class MockRoversRepository: RoversRepositoryProtocol {
    let latestSol: Int
    let pages: [Int: RoverPhotoPage]
    let error: Error?
    private(set) var requestedSols: [Int] = []
    private(set) var requestedPages: [Int] = []

    init(latestSol: Int, pages: [Int: RoverPhotoPage], error: Error? = nil) {
        self.latestSol = latestSol
        self.pages = pages
        self.error = error
    }

    func fetchLatestSol(for rover: RoverName) async throws -> Int {
        if let error {
            throw error
        }
        return latestSol
    }

    func fetchPhotos(rover: RoverName, sol: Int, camera: RoverCamera, page: Int) async throws -> RoverPhotoPage {
        if let error {
            throw error
        }
        requestedSols.append(sol)
        requestedPages.append(page)
        return pages[page] ?? RoverPhotoPage(photos: [], total: 0, hasMore: false)
    }
}

private func makeRoverPhotos(range: Range<Int>) -> [RoverPhoto] {
    range.map { index in
        RoverPhoto(
            id: "msl-\(index)",
            rover: .curiosity,
            sol: 5050,
            instrument: "NAV_LEFT_B",
            cameraName: "Navcam",
            cameraFullName: "Navigation Camera",
            thumbnailURL: URL(string: "https://example.com/\(index).jpg"),
            imageURL: URL(string: "https://example.com/\(index).jpg"),
            earthDate: nil,
            caption: "Sample",
            credit: "NASA/JPL-Caltech"
        )
    }
}

private struct MockEPICRepository: EPICRepositoryProtocol {
    let result: Result<[EPICEntry], Error>

    func fetchEntries(for date: Date) async throws -> [EPICEntry] {
        try result.get()
    }
}

private enum MockError: LocalizedError {
    case sample

    var errorDescription: String? {
        "Sample failure"
    }
}
