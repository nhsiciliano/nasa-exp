import Foundation
import SwiftData
import XCTest
@testable import nasa_exp

@MainActor
final class APODHDImageTests: XCTestCase {
    func test_entryFromDTO_keepsStandardURLAndHDURLSeparate() {
        let entry = Self.makeEntry(hdurl: "https://apod.nasa.gov/apod/image/2603/nebula_hd.jpg")

        guard case let .image(url, hdURL) = entry.media else {
            return XCTFail("Expected image media")
        }
        XCTAssertEqual(url.absoluteString, "https://apod.nasa.gov/apod/image/2603/nebula.jpg")
        XCTAssertEqual(hdURL?.absoluteString, "https://apod.nasa.gov/apod/image/2603/nebula_hd.jpg")
        XCTAssertEqual(entry.shareURL, url)
    }

    func test_entryFromDTO_withoutHDURL_hasNilHDURL() {
        let entry = Self.makeEntry(hdurl: nil)

        guard case let .image(_, hdURL) = entry.media else {
            return XCTFail("Expected image media")
        }
        XCTAssertNil(hdURL)
    }

    func test_favoriteDraft_carriesHDURLAndRoundTripsThroughStore() throws {
        let original = Self.makeEntry(hdurl: "https://apod.nasa.gov/apod/image/2603/nebula_hd.jpg")
        let draft = original.favoriteDraft

        XCTAssertEqual(draft.mediaURL?.absoluteString, "https://apod.nasa.gov/apod/image/2603/nebula.jpg")
        XCTAssertEqual(draft.hdMediaURL?.absoluteString, "https://apod.nasa.gov/apod/image/2603/nebula_hd.jpg")

        let container = try ModelContainer(
            for: FavoriteItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        FavoriteStore.add(draft, in: context)

        let item = try XCTUnwrap(try context.fetch(FetchDescriptor<FavoriteItem>()).first)
        XCTAssertEqual(item.hdMediaURLString, "https://apod.nasa.gov/apod/image/2603/nebula_hd.jpg")

        guard case let .image(url, hdURL) = APODEntry(favoriteItem: item).media else {
            return XCTFail("Expected image media")
        }
        XCTAssertEqual(url.absoluteString, "https://apod.nasa.gov/apod/image/2603/nebula.jpg")
        XCTAssertEqual(hdURL?.absoluteString, "https://apod.nasa.gov/apod/image/2603/nebula_hd.jpg")
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

    private static func makeEntry(hdurl: String?) -> APODEntry {
        APODEntry(dto: APODResponseDTO(
            title: "Nebula",
            explanation: "A bright nebula.",
            date: "2026-03-13",
            mediaType: "image",
            url: "https://apod.nasa.gov/apod/image/2603/nebula.jpg",
            hdurl: hdurl,
            copyright: "Jane Doe"
        ))
    }
}
