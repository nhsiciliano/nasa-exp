import Foundation
import SwiftData
import XCTest
@testable import nasa_exp

/// `FavoriteStore.upsert` and `refreshIfFavorite` complete favorites saved by older versions (P1.16).
@MainActor
final class FavoriteStoreUpsertTests: XCTestCase {
    private let savedAt = Date(timeIntervalSince1970: 1_780_000_000)

    func test_upsert_legacyFavorite_fillsMissingMetadataWithoutDuplicating() throws {
        let container = try makeContainer()
        try insert(legacyFavorite(key: "apod-2026-03-13", type: .apod, remoteID: "2026-03-13",
                                  mediaURLString: "https://example.com/apod.jpg"), in: container)
        let liveEntry = APODEntry(record: APODRecord(
            id: "2026-03-13",
            title: "Nebula",
            explanation: "A bright nebula.",
            credit: "Jane Doe",
            pageURL: URL(string: "https://science.nasa.gov/apod/nebula"),
            imageURL: URL(string: "https://example.com/apod.jpg"),
            videoURL: nil
        ))

        FavoriteStore.upsert(liveEntry.favoriteDraft, in: ModelContext(container))

        let stored = try storedFavorites(in: container)
        XCTAssertEqual(stored.count, 1)
        let favorite = try XCTUnwrap(stored.first)
        XCTAssertEqual(favorite.createdAt, savedAt)
        XCTAssertEqual(favorite.originalDate, liveEntry.date)
        XCTAssertEqual(favorite.copyright, "Jane Doe")
        XCTAssertEqual(favorite.mediaKind, .image)
        XCTAssertEqual(favorite.pageURL, liveEntry.shareURL)
        XCTAssertEqual(favorite.thumbnailURL, liveEntry.thumbnailURL)
        XCTAssertEqual(favorite.hdMediaURL, URL(string: "https://example.com/apod.jpg"))
    }

    func test_upsert_draftWithoutMetadata_keepsStoredValues() throws {
        let container = try makeContainer()
        let photo = RoverPhoto(
            id: "msl-1",
            rover: .curiosity,
            sol: 5050,
            instrument: "NAV_LEFT_B",
            cameraName: "Navcam",
            cameraFullName: "Navigation Camera",
            thumbnailURL: URL(string: "https://example.com/thumb.jpg"),
            imageURL: URL(string: "https://example.com/full.jpg"),
            earthDate: savedAt,
            caption: "",
            credit: "NASA/JPL-Caltech"
        )
        FavoriteStore.upsert(photo.favoriteDraft, in: ModelContext(container))

        FavoriteStore.upsert(FavoriteDraft(
            contentType: .rover,
            remoteID: "msl-1",
            title: "Curiosity - Navcam",
            subtitle: "Sol 5050",
            details: "",
            mediaURL: nil
        ), in: ModelContext(container))

        let favorite = try XCTUnwrap(storedFavorites(in: container).first)
        XCTAssertEqual(favorite.subtitle, "Sol 5050")
        XCTAssertEqual(favorite.mediaURLString, "https://example.com/full.jpg")
        XCTAssertEqual(favorite.sol, 5050)
        XCTAssertEqual(favorite.originalDate, savedAt)
        XCTAssertEqual(favorite.instrument, "NAV_LEFT_B")
        XCTAssertEqual(favorite.credit, "NASA/JPL-Caltech")
        XCTAssertEqual(favorite.thumbnailURLString, "https://example.com/thumb.jpg")
    }

    func test_upsert_legacyEPICFavoriteWithAPIKey_storesLiveURLWithoutKey() throws {
        let container = try makeContainer()
        try insert(legacyFavorite(
            key: "epic-20261019003633",
            type: .epic,
            remoteID: "20261019003633",
            mediaURLString: "https://api.nasa.gov/EPIC/archive/natural/2026/10/19/png/epic_1b_20261019003633.png?api_key=SECRET"
        ), in: container)
        let liveEntry = EPICEntry(dto: EPICEntryDTO(
            identifier: "20261019003633",
            caption: "Earth from orbit",
            image: "epic_1b_20261019003633",
            date: "2026-10-19 00:31:45",
            centroidCoordinates: .init(lat: 12.34, lon: -56.78)
        ))

        FavoriteStore.upsert(liveEntry.favoriteDraft, in: ModelContext(container))

        let favorite = try XCTUnwrap(storedFavorites(in: container).first)
        XCTAssertEqual(favorite.mediaURL, liveEntry.imageURL)
        XCTAssertFalse(favorite.mediaURLString.contains("api_key"))
        XCTAssertEqual(favorite.latitude, 12.34)
        XCTAssertEqual(favorite.longitude, -56.78)
        XCTAssertEqual(favorite.createdAt, savedAt)
    }

    func test_upsert_draftURLsWithAPIKey_dropOnlyTheKey() throws {
        let container = try makeContainer()

        FavoriteStore.upsert(FavoriteDraft(
            contentType: .epic,
            remoteID: "20261019003633",
            title: "EPIC - 20261019003633",
            subtitle: "",
            details: "",
            mediaURL: URL(string: "https://api.nasa.gov/EPIC/archive/natural/2026/10/19/png/a.png?api_key=SECRET&v=2"),
            thumbnailURL: URL(string: "https://api.nasa.gov/EPIC/archive/natural/2026/10/19/thumbs/a.jpg?api_key=SECRET")
        ), in: ModelContext(container))

        let favorite = try XCTUnwrap(storedFavorites(in: container).first)
        XCTAssertEqual(favorite.mediaURLString, "https://api.nasa.gov/EPIC/archive/natural/2026/10/19/png/a.png?v=2")
        XCTAssertEqual(favorite.thumbnailURLString, "https://api.nasa.gov/EPIC/archive/natural/2026/10/19/thumbs/a.jpg")
    }

    func test_refreshIfFavorite_whenNotFavorite_returnsFalseAndStoresNothing() throws {
        let container = try makeContainer()
        let draft = FavoriteDraft(
            contentType: .apod,
            remoteID: "2026-03-13",
            title: "Nebula",
            subtitle: "",
            details: "",
            mediaURL: URL(string: "https://example.com/apod.jpg")
        )

        XCTAssertFalse(FavoriteStore.refreshIfFavorite(draft, in: ModelContext(container)))
        XCTAssertTrue(try storedFavorites(in: container).isEmpty)
    }

    func test_refreshIfFavorite_whenFavorite_returnsTrueAndFillsMetadata() throws {
        let container = try makeContainer()
        try insert(legacyFavorite(key: "apod-2026-03-13", type: .apod, remoteID: "2026-03-13",
                                  mediaURLString: "https://example.com/apod.jpg"), in: container)
        let draft = FavoriteDraft(
            contentType: .apod,
            remoteID: "2026-03-13",
            title: "Nebula",
            subtitle: "13 de marzo de 2026",
            details: "A bright nebula.",
            mediaURL: URL(string: "https://example.com/apod.jpg"),
            copyright: "Jane Doe",
            pageURL: URL(string: "https://science.nasa.gov/apod/nebula")
        )

        XCTAssertTrue(FavoriteStore.refreshIfFavorite(draft, in: ModelContext(container)))

        let favorite = try XCTUnwrap(storedFavorites(in: container).first)
        XCTAssertEqual(favorite.copyright, "Jane Doe")
        XCTAssertEqual(favorite.pageURLString, "https://science.nasa.gov/apod/nebula")
        XCTAssertEqual(favorite.createdAt, savedAt)
    }

    // MARK: - Helpers

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: FavoriteItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// A favorite as stored before the metadata fields existed.
    private func legacyFavorite(
        key: String,
        type: FavoriteContentType,
        remoteID: String,
        mediaURLString: String
    ) -> FavoriteItem {
        FavoriteItem(
            key: key,
            contentTypeRaw: type.rawValue,
            remoteID: remoteID,
            title: "Saved title",
            subtitle: "Saved subtitle",
            details: "Saved details",
            mediaURLString: mediaURLString,
            createdAt: savedAt
        )
    }

    private func insert(_ favorite: FavoriteItem, in container: ModelContainer) throws {
        let context = ModelContext(container)
        context.insert(favorite)
        try context.save()
    }

    /// Reads from a fresh context so values come back from the store.
    private func storedFavorites(in container: ModelContainer) throws -> [FavoriteItem] {
        try ModelContext(container).fetch(FetchDescriptor<FavoriteItem>())
    }
}
