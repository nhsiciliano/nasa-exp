import Foundation
import XCTest
@testable import nasa_exp

final class APODVideoEmbedTests: XCTestCase {
    func test_embedURL_keepsYouTubeEmbedQueryAndForcesInlinePlayback() {
        let url = URL(string: "https://www.youtube.com/embed/abc123?rel=0&playsinline=0")!

        XCTAssertEqual(
            APODVideoEmbed.embedURL(for: url)?.absoluteString,
            "https://www.youtube-nocookie.com/embed/abc123?rel=0&playsinline=1"
        )
    }

    func test_embedURL_convertsYouTubeWatchAndShortLinks() {
        XCTAssertEqual(
            APODVideoEmbed.embedURL(for: URL(string: "https://www.youtube.com/watch?v=abc123&t=10")!)?.absoluteString,
            "https://www.youtube-nocookie.com/embed/abc123?playsinline=1"
        )
        XCTAssertEqual(
            APODVideoEmbed.embedURL(for: URL(string: "https://youtu.be/abc123")!)?.absoluteString,
            "https://www.youtube-nocookie.com/embed/abc123?playsinline=1"
        )
        XCTAssertEqual(
            APODVideoEmbed.embedURL(for: URL(string: "https://www.youtube-nocookie.com/embed/abc123")!)?.absoluteString,
            "https://www.youtube-nocookie.com/embed/abc123?playsinline=1"
        )
    }

    func test_embedURL_handlesVimeoPlayerAndPageLinks() {
        let playerURL = URL(string: "https://player.vimeo.com/video/987654?h=xyz")!

        XCTAssertEqual(APODVideoEmbed.embedURL(for: playerURL), playerURL)
        XCTAssertEqual(
            APODVideoEmbed.embedURL(for: URL(string: "https://vimeo.com/987654")!)?.absoluteString,
            "https://player.vimeo.com/video/987654"
        )
    }

    func test_embedURL_whenHostIsNotSupported_returnsNil() {
        XCTAssertNil(APODVideoEmbed.embedURL(for: URL(string: "https://apod.nasa.gov/apod/image/2610/clip.mp4")!))
        XCTAssertNil(APODVideoEmbed.embedURL(for: URL(string: "https://www.youtube.com/channel/xyz")!))
        XCTAssertNil(APODVideoEmbed.embedURL(for: URL(string: "https://vimeo.com/channels/staffpicks")!))
    }
}
