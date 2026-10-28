import Foundation
import XCTest
@testable import nasa_exp

final class APODShareTextTests: XCTestCase {
    func test_shareText_includesTitleDateAndCleanedCopyright() {
        let entry = makeEntry(copyright: "\nJane Doe\n  & John Roe ")

        XCTAssertEqual(entry.shareText, "Nebula · APOD \(entry.displayDate) · Crédito: Jane Doe & John Roe")
    }

    func test_shareText_whenCopyrightIsMissing_creditsNASA() {
        XCTAssertTrue(makeEntry(copyright: nil).shareText.hasSuffix("· Crédito: NASA"))
        XCTAssertTrue(makeEntry(copyright: "   ").shareText.hasSuffix("· Crédito: NASA"))
    }

    func test_videoEntry_usesScreenWidthPosterForShareAndSave() throws {
        let entry = makeVideoEntry(posterURL: Self.posterURL)
        let screenPoster = APODImageURL.resized(Self.posterURL, width: APODEntry.screenImageWidth)

        XCTAssertTrue(entry.isVideo)
        XCTAssertEqual(entry.stillImageURL, screenPoster)
        XCTAssertEqual(
            entry.photoSaveItem,
            PhotoSaveItem(imageURL: screenPoster, title: "Eagle Pillars", caption: entry.shareMessage, credit: "Jane Doe")
        )
    }

    func test_videoEntry_shareMessageAddsArticleLinkToCaption() {
        let entry = makeVideoEntry(posterURL: Self.posterURL)

        XCTAssertEqual(entry.shareMessage, "\(entry.shareText)\nhttps://example.com/apod-2026-october-18/")
        XCTAssertTrue(entry.shareMessage.contains("· Crédito: Jane Doe"))
    }

    func test_videoEntryWithoutPoster_hasNothingToShareOrSave() {
        let entry = makeVideoEntry(posterURL: nil)

        XCTAssertNil(entry.stillImageURL)
        XCTAssertNil(entry.photoSaveItem)
    }

    func test_imageEntry_sharesScreenImageAndSavesOriginal() throws {
        let entry = makeEntry(copyright: "Jane Doe")
        let original = try XCTUnwrap(URL(string: "https://example.com/apod.jpg"))

        XCTAssertFalse(entry.isVideo)
        XCTAssertEqual(entry.stillImageURL, APODImageURL.resized(original, width: APODEntry.screenImageWidth))
        XCTAssertEqual(entry.photoSaveItem?.imageURL, original)
        XCTAssertEqual(entry.shareMessage, entry.shareText)
    }

    private static let posterURL = URL(string: "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/SonifiedEagleNebulaPillars.jpg")!

    private func makeVideoEntry(posterURL: URL?) -> APODEntry {
        APODEntry(record: APODRecord(
            id: "2026-10-18",
            title: "Eagle Pillars",
            explanation: "Sonified pillars.",
            credit: "Jane Doe",
            pageURL: URL(string: "https://example.com/apod-2026-october-18/"),
            imageURL: posterURL,
            videoURL: URL(string: "https://www.youtube.com/embed/DzrCEm1ZBRY?rel=0")
        ))
    }

    private func makeEntry(copyright: String?) -> APODEntry {
        APODEntry(record: APODRecord(
            id: "2026-03-13",
            title: "Nebula",
            explanation: "A bright nebula.",
            credit: copyright,
            pageURL: URL(string: "https://example.com/apod-2026-march-13/"),
            imageURL: URL(string: "https://example.com/apod.jpg"),
            videoURL: nil
        ))
    }
}
