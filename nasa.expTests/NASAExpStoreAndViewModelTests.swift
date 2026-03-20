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
            subtitle: "10 mar 2026",
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
        XCTAssertEqual(roverPhoto.cameraName, "NAVCAM")
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

    func test_roversViewModel_search_limitsTo100Results() async {
        let photos = (0..<120).map { index in
            RoverPhoto(dto: RoverPhotoDTO(
                id: index,
                imgSrc: "https://example.com/\(index).jpg",
                earthDate: "2026-03-10",
                camera: .init(name: "NAVCAM", fullName: "Navigation Camera"),
                rover: .init(name: "Curiosity", status: "active", launchDate: "2011-11-26", landingDate: "2012-08-06")
            ))
        }
        let viewModel = RoversViewModel(repository: MockRoversRepository(result: .success(photos)))

        await viewModel.search()

        guard case let .loaded(result) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        XCTAssertEqual(result.count, 100)
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
}

private struct MockRoversRepository: RoversRepositoryProtocol {
    let result: Result<[RoverPhoto], Error>

    func fetchPhotos(rover: RoverName, earthDate: Date, camera: RoverCamera) async throws -> [RoverPhoto] {
        try result.get()
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
