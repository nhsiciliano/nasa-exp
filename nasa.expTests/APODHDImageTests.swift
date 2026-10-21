import Foundation
import SwiftData
import XCTest
@testable import nasa_exp

@MainActor
final class APODHDImageTests: XCTestCase {
    func test_entryFromRecord_showsResizedImageAndKeepsOriginalAsHD() {
        let entry = Self.makeEntry()

        guard case let .image(url, hdURL) = entry.media else {
            return XCTFail("Expected image media")
        }
        XCTAssertEqual(url.absoluteString, Self.screenURL)
        XCTAssertEqual(hdURL?.absoluteString, Self.originalURL)
        XCTAssertEqual(entry.shareURL?.absoluteString, "https://science.nasa.gov/image-article/apod-2026-march-13-nebula/")
    }

    func test_entryFromRecord_withNonCDNImage_usesSameURLForScreenAndHD() {
        let entry = APODEntry(record: APODRecord(
            id: "2026-03-13",
            title: "Nebula",
            explanation: "A bright nebula.",
            credit: nil,
            pageURL: nil,
            imageURL: URL(string: "https://example.com/nebula.jpg"),
            videoURL: nil
        ))

        guard case let .image(url, hdURL) = entry.media else {
            return XCTFail("Expected image media")
        }
        XCTAssertEqual(url, hdURL)
    }

    func test_favoriteDraft_carriesHDURLAndRoundTripsThroughStore() throws {
        let original = Self.makeEntry()
        let draft = original.favoriteDraft

        XCTAssertEqual(draft.mediaURL?.absoluteString, Self.screenURL)
        XCTAssertEqual(draft.hdMediaURL?.absoluteString, Self.originalURL)

        let container = try ModelContainer(
            for: FavoriteItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        FavoriteStore.add(draft, in: context)

        let item = try XCTUnwrap(try context.fetch(FetchDescriptor<FavoriteItem>()).first)
        XCTAssertEqual(item.hdMediaURLString, Self.originalURL)

        guard case let .image(url, hdURL) = APODEntry(favoriteItem: item).media else {
            return XCTFail("Expected image media")
        }
        XCTAssertEqual(url.absoluteString, Self.screenURL)
        XCTAssertEqual(hdURL?.absoluteString, Self.originalURL)
    }

    func test_legacyFavoriteWithoutHDURL_rebuildsImageWithNilHDURL() {
        let item = FavoriteItem(
            key: "apod-2026-03-13",
            contentTypeRaw: FavoriteContentType.apod.rawValue,
            remoteID: "2026-03-13",
            title: "Nebula",
            subtitle: "13 de marzo de 2026",
            details: "A bright nebula.",
            mediaURLString: "https://apod.nasa.gov/apod/image/2603/nebula.jpg"
        )

        guard case let .image(_, hdURL) = APODEntry(favoriteItem: item).media else {
            return XCTFail("Expected image media")
        }
        XCTAssertNil(hdURL)
    }

    private static let originalURL = "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/march/nebula.jpg"
    private static let screenURL = originalURL + "?w=1280&fit=clip"

    private static func makeEntry() -> APODEntry {
        APODEntry(record: APODRecord(
            id: "2026-03-13",
            title: "Nebula",
            explanation: "A bright nebula.",
            credit: "Jane Doe",
            pageURL: URL(string: "https://science.nasa.gov/image-article/apod-2026-march-13-nebula/"),
            imageURL: URL(string: originalURL),
            videoURL: nil
        ))
    }
}
