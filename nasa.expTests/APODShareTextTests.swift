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
