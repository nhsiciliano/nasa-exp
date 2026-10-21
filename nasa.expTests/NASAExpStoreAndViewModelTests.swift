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

    func test_favoriteModels_legacyFavoritesWithoutMetadata_fallBackToStoredFields() throws {
        let container = try makeInMemoryFavoritesContainer()
        let writeContext = ModelContext(container)
        for legacyFavorite in makeLegacyFavorites() {
            writeContext.insert(legacyFavorite)
        }
        try writeContext.save()

        let readContext = ModelContext(container)
        let stored = try readContext.fetch(FetchDescriptor<FavoriteItem>())
        let favorites = Dictionary(uniqueKeysWithValues: stored.map { ($0.contentType, $0) })
        XCTAssertEqual(favorites.count, 3)
        XCTAssertTrue(stored.allSatisfy { $0.originalDate == nil && $0.sol == nil && $0.latitude == nil })

        let apodEntry = APODEntry(favoriteItem: try XCTUnwrap(favorites[.apod]))
        let apodDay = Calendar.current.dateComponents([.year, .month, .day], from: apodEntry.date)
        XCTAssertEqual(apodEntry.id, "2026-03-13")
        XCTAssertEqual([apodDay.year, apodDay.month, apodDay.day], [2026, 3, 13])
        XCTAssertNil(apodEntry.copyright)
        XCTAssertEqual(mediaSummary(apodEntry.media), "image https://example.com/apod.jpg")

        let roverPhoto = RoverPhoto(favoriteItem: try XCTUnwrap(favorites[.rover]))
        XCTAssertEqual(roverPhoto.roverName, "Curiosity")
        XCTAssertEqual(roverPhoto.rover, .curiosity)
        XCTAssertEqual(roverPhoto.cameraName, "NAVCAM")
        XCTAssertEqual(roverPhoto.cameraFullName, "NAVCAM")
        XCTAssertEqual(roverPhoto.sol, 1000)
        XCTAssertEqual(roverPhoto.instrument, "")
        XCTAssertNil(roverPhoto.earthDate)
        XCTAssertEqual(roverPhoto.displayDate, "Sol 1000 · 30 may 2015")
        XCTAssertEqual(roverPhoto.credit, RoverPhoto.defaultCredit)
        XCTAssertEqual(roverPhoto.thumbnailURL, roverPhoto.imageURL)

        let epicEntry = EPICEntry(favoriteItem: try XCTUnwrap(favorites[.epic]))
        XCTAssertEqual(epicEntry.id, "202603130001")
        XCTAssertEqual(epicEntry.title, "EPIC - 202603130001")
        XCTAssertEqual(epicEntry.caption, "Earth from orbit")
        XCTAssertEqual(epicEntry.latitude, 0)
        XCTAssertEqual(epicEntry.longitude, 0)
    }

    func test_favoriteStore_roundTrip_preservesAPODMetadata() throws {
        let original = APODEntry(dto: APODResponseDTO(
            title: "Nebula",
            explanation: "A bright nebula.",
            date: "2026-03-13",
            mediaType: "image",
            url: "https://apod.nasa.gov/apod/image/2603/nebula.jpg",
            hdurl: nil,
            copyright: "Jane Doe"
        ))

        let restored = try roundTrip(original.favoriteDraft, rebuild: APODEntry.init(favoriteItem:))

        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.explanation, original.explanation)
        XCTAssertEqual(restored.date, original.date)
        XCTAssertEqual(restored.displayDate, original.displayDate)
        XCTAssertEqual(restored.copyright, "Jane Doe")
        XCTAssertEqual(restored.shareURL, original.shareURL)
        XCTAssertEqual(mediaSummary(restored.media), mediaSummary(original.media))
    }

    func test_favoriteStore_roundTrip_apodPrefersStoredMediaKindOverURLHeuristic() throws {
        let video = APODEntry(dto: APODResponseDTO(
            title: "Launch",
            explanation: "A launch timelapse.",
            date: "2026-10-20",
            mediaType: "video",
            url: "https://apod.nasa.gov/apod/image/2610/launch.webm",
            hdurl: nil,
            copyright: nil
        ))
        let interactive = APODEntry(dto: APODResponseDTO(
            title: "Interactive sky",
            explanation: "An interactive page.",
            date: "2026-10-21",
            mediaType: "other",
            url: "https://apod.nasa.gov/apod/ap261021.html",
            hdurl: nil,
            copyright: nil
        ))

        let restoredVideo = try roundTrip(video.favoriteDraft, rebuild: APODEntry.init(favoriteItem:))
        let restoredInteractive = try roundTrip(interactive.favoriteDraft, rebuild: APODEntry.init(favoriteItem:))

        XCTAssertEqual(mediaSummary(restoredVideo.media), "video https://apod.nasa.gov/apod/image/2610/launch.webm")
        XCTAssertEqual(mediaSummary(restoredInteractive.media), "unsupported")
    }

    func test_favoriteStore_roundTrip_preservesCuriosityMetadata() throws {
        let original = RoverPhoto(dto: MSLRawImageDTO(
            id: 1647660,
            imageid: "ML0_845799994EDR_F1251326ML0050000M_",
            sol: 5050,
            instrument: "MAST_LEFT",
            httpsUrl: "https://mars.nasa.gov/msl-raw-images/mast.JPG",
            dateTaken: "2026-10-20T21:39:17.000Z",
            title: "Sol 5050: Left Mastcam",
            description: "This image was taken by Left Mastcam onboard NASA's Mars rover Curiosity on Sol 5050.",
            imageCredit: "NASA/JPL-Caltech/MSSS",
            isThumbnail: false,
            extended: nil
        ))

        let restored = try roundTrip(original.favoriteDraft, rebuild: RoverPhoto.init(favoriteItem:))

        XCTAssertEqual(restored, original)
        XCTAssertEqual(restored.displayDate, original.displayDate)
    }

    func test_favoriteStore_roundTrip_preservesPerseveranceMetadata() throws {
        let original = RoverPhoto(dto: Mars2020RawImageDTO(
            imageid: "ZLF_0100_0675835172_000ECM_N0040000ZCAM00502_1100LMJ",
            sol: 100,
            camera: .init(instrument: "MCZ_LEFT"),
            imageFiles: .init(
                small: "https://mars.nasa.gov/mars2020-raw-images/zcam_320.jpg",
                medium: "https://mars.nasa.gov/mars2020-raw-images/zcam_800.jpg",
                large: "https://mars.nasa.gov/mars2020-raw-images/zcam_1200.jpg",
                fullRes: "https://mars.nasa.gov/mars2020-raw-images/zcam.png"
            ),
            title: "Mars Perseverance Sol 100: Left Mastcam-Z Camera",
            caption: "NASA's Mars Perseverance rover acquired this image using its Left Mastcam-Z camera.",
            credit: "NASA/JPL-Caltech/ASU",
            dateTakenUtc: "2021-06-01T14:24:18.590",
            sampleType: "Full"
        ))

        let restored = try roundTrip(original.favoriteDraft, rebuild: RoverPhoto.init(favoriteItem:))

        XCTAssertEqual(restored, original)
        XCTAssertEqual(restored.displayDate, original.displayDate)
        XCTAssertNotEqual(restored.thumbnailURL, restored.imageURL)
    }

    func test_favoriteStore_roundTrip_preservesEPICMetadata() throws {
        let original = EPICEntry(dto: EPICEntryDTO(
            identifier: "20261019003633",
            caption: "This image was taken by NASA's EPIC camera onboard the NOAA DSCOVR spacecraft",
            image: "epic_1b_20261019003633",
            date: "2026-10-19 00:31:45",
            centroidCoordinates: .init(lat: 12.34, lon: -56.78)
        ))

        let restored = try roundTrip(original.favoriteDraft, rebuild: EPICEntry.init(favoriteItem:))

        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.caption, original.caption)
        XCTAssertEqual(restored.date, original.date)
        XCTAssertEqual(restored.displayDate, original.displayDate)
        XCTAssertEqual(restored.latitude, 12.34)
        XCTAssertEqual(restored.longitude, -56.78)
        XCTAssertEqual(restored.coordinateSummary, "Lat 12.34 | Lon -56.78")
        XCTAssertEqual(restored.imageURL, original.imageURL)
    }

    func test_favoriteStore_lightweightMigration_opensStoreCreatedWithLegacySchema() throws {
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FavoritesMigration-\(UUID().uuidString)", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("Favorites.store")
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: storeDirectory) }

        try autoreleasepool {
            let legacySchema = Schema([LegacyFavoritesSchema.FavoriteItem.self])
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: ModelConfiguration(schema: legacySchema, url: storeURL)
            )
            let legacyContext = ModelContext(legacyContainer)
            legacyContext.insert(LegacyFavoritesSchema.FavoriteItem(
                key: "rover-42",
                contentTypeRaw: FavoriteContentType.rover.rawValue,
                remoteID: "42",
                title: "Curiosity - NAVCAM",
                subtitle: "Sol 1000 · 30 may 2015",
                details: "Navigation Camera",
                mediaURLString: "https://example.com/rover.jpg",
                createdAt: .now
            ))
            try legacyContext.save()
        }

        let container = try ModelContainer(
            for: FavoriteItem.self,
            configurations: ModelConfiguration(url: storeURL)
        )
        let context = ModelContext(container)
        let migrated = try XCTUnwrap(context.fetch(FetchDescriptor<FavoriteItem>()).first)

        XCTAssertEqual(migrated.key, "rover-42")
        XCTAssertNil(migrated.originalDate)
        XCTAssertNil(migrated.sol)
        XCTAssertNil(migrated.thumbnailURLString)
        XCTAssertEqual(RoverPhoto(favoriteItem: migrated).sol, 1000)

        let newDraft = FavoriteDraft(
            contentType: .epic,
            remoteID: "20261019003633",
            title: "EPIC - 20261019003633",
            subtitle: "19 oct 2026, 0:31",
            details: "Earth from orbit",
            mediaURL: URL(string: "https://example.com/epic.png"),
            originalDate: Date(timeIntervalSince1970: 1_792_370_000),
            latitude: 12.34,
            longitude: -56.78
        )
        FavoriteStore.add(newDraft, in: context)

        XCTAssertTrue(FavoriteStore.contains(newDraft, in: context))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<FavoriteItem>()), 2)

        let reloadedEPIC = try XCTUnwrap(ModelContext(container).fetch(FetchDescriptor<FavoriteItem>()).first { $0.contentType == .epic })
        XCTAssertEqual(reloadedEPIC.latitude, 12.34)
        XCTAssertEqual(reloadedEPIC.longitude, -56.78)
    }

    /// Saves the draft through `FavoriteStore` and rebuilds the domain model from a fresh context,
    /// so the values come back from the store instead of the inserted instance.
    private func roundTrip<Model>(_ draft: FavoriteDraft, rebuild: (FavoriteItem) -> Model) throws -> Model {
        let container = try makeInMemoryFavoritesContainer()
        FavoriteStore.add(draft, in: ModelContext(container))

        let readContext = ModelContext(container)
        let stored = try readContext.fetch(FetchDescriptor<FavoriteItem>())
        XCTAssertEqual(stored.count, 1)
        return rebuild(try XCTUnwrap(stored.first))
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

private func makeInMemoryFavoritesContainer() throws -> ModelContainer {
    try ModelContainer(
        for: FavoriteItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

/// Favorites as they were stored before the metadata fields existed.
private func makeLegacyFavorites() -> [FavoriteItem] {
    [
        FavoriteItem(
            key: "apod-2026-03-13",
            contentTypeRaw: FavoriteContentType.apod.rawValue,
            remoteID: "2026-03-13",
            title: "Nebula",
            subtitle: "13 de marzo de 2026",
            details: "A bright nebula.",
            mediaURLString: "https://example.com/apod.jpg"
        ),
        FavoriteItem(
            key: "rover-42",
            contentTypeRaw: FavoriteContentType.rover.rawValue,
            remoteID: "42",
            title: "Curiosity - NAVCAM",
            subtitle: "Sol 1000 · 30 may 2015",
            details: "Navigation Camera",
            mediaURLString: "https://example.com/rover.jpg"
        ),
        FavoriteItem(
            key: "epic-202603130001",
            contentTypeRaw: FavoriteContentType.epic.rawValue,
            remoteID: "202603130001",
            title: "EPIC - 202603130001",
            subtitle: "13 mar 2026",
            details: "Earth from orbit",
            mediaURLString: "https://example.com/epic.png"
        )
    ]
}

private func mediaSummary(_ media: APODEntry.Media) -> String {
    switch media {
    case let .image(url, _):
        return "image \(url.absoluteString)"
    case let .video(url):
        return "video \(url.absoluteString)"
    case .unsupported:
        return "unsupported"
    }
}

/// Frozen copy of the `FavoriteItem` schema shipped before the metadata fields were added.
/// Used to create an on-disk store that the current schema must open through lightweight migration.
private enum LegacyFavoritesSchema {
    @Model
    final class FavoriteItem {
        @Attribute(.unique) var key: String
        var contentTypeRaw: String
        var remoteID: String
        var title: String
        var subtitle: String
        var details: String
        var mediaURLString: String
        var createdAt: Date

        init(
            key: String,
            contentTypeRaw: String,
            remoteID: String,
            title: String,
            subtitle: String,
            details: String,
            mediaURLString: String,
            createdAt: Date
        ) {
            self.key = key
            self.contentTypeRaw = contentTypeRaw
            self.remoteID = remoteID
            self.title = title
            self.subtitle = subtitle
            self.details = details
            self.mediaURLString = mediaURLString
            self.createdAt = createdAt
        }
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

    func fetchLatest() async throws -> [EPICEntry] {
        try result.get()
    }
}

private enum MockError: LocalizedError {
    case sample

    var errorDescription: String? {
        "Sample failure"
    }
}
