import CoreGraphics
import Foundation
import ImageIO
import XCTest
@testable import nasa_exp

@MainActor
final class NASAExpWidgetTests: XCTestCase {
    // MARK: - APODPublicationSchedule

    func test_nextRefresh_whenShowingTodaysEntry_waitsForNextPublication() throws {
        let now = try utcDate("2026-10-21T19:00:00Z") // 15:00 in New York

        let refresh = APODPublicationSchedule.nextRefresh(after: now, showing: "2026-10-21")

        XCTAssertEqual(refresh, try utcDate("2026-10-22T04:15:00Z")) // 00:15 in New York
    }

    func test_nextRefresh_lateInTheEasternDay_comparesAgainstTheEasternDate() throws {
        // 03:30 UTC on Oct 22 is still Oct 21 in New York (UTC-4 in October).
        let now = try utcDate("2026-10-22T03:30:00Z")

        let refresh = APODPublicationSchedule.nextRefresh(after: now, showing: "2026-10-21")

        XCTAssertEqual(refresh, try utcDate("2026-10-22T04:15:00Z"))
    }

    func test_nextRefresh_whenEntryIsStaleOrMissing_retriesAfterRetryInterval() throws {
        let now = try utcDate("2026-10-22T04:10:00Z") // 00:10 in New York, still showing yesterday
        let retry = now.addingTimeInterval(APODPublicationSchedule.retryInterval)

        XCTAssertEqual(APODPublicationSchedule.nextRefresh(after: now, showing: "2026-10-21"), retry)
        XCTAssertEqual(APODPublicationSchedule.nextRefresh(after: now, showing: nil), retry)
    }

    func test_nextPublication_acrossDaylightSavingEnd_staysAtSameEasternTime() throws {
        // US daylight saving time ends on Nov 1, 2026: New York goes from UTC-4 to UTC-5.
        let now = try utcDate("2026-11-01T17:00:00Z")

        XCTAssertEqual(APODPublicationSchedule.nextPublication(after: now), try utcDate("2026-11-02T05:15:00Z"))
    }

    // MARK: - ImageDownsampler

    func test_maxPixelSize_coversTargetWithoutUpscaling() {
        let landscape = CGSize(width: 3000, height: 2000)
        let portrait = CGSize(width: 2000, height: 3000)

        XCTAssertEqual(ImageDownsampler.maxPixelSize(forImageSize: landscape, filling: CGSize(width: 300, height: 300)), 450)
        XCTAssertEqual(ImageDownsampler.maxPixelSize(forImageSize: portrait, filling: CGSize(width: 600, height: 300)), 900)
        XCTAssertEqual(ImageDownsampler.maxPixelSize(forImageSize: CGSize(width: 200, height: 100), filling: CGSize(width: 600, height: 600)), 200)
    }

    func test_downsample_cropsToTargetAspectAtTargetSize() throws {
        let data = try makePNGData(width: 300, height: 200)

        let image = try XCTUnwrap(ImageDownsampler.downsample(data, filling: CGSize(width: 100, height: 100)))

        XCTAssertEqual(image.width, 100)
        XCTAssertEqual(image.height, 100)
    }

    func test_downsample_whenTargetIsLarger_keepsResolutionAndCropsAspect() throws {
        let data = try makePNGData(width: 300, height: 200)

        let image = try XCTUnwrap(ImageDownsampler.downsample(data, filling: CGSize(width: 1000, height: 500)))

        XCTAssertEqual(image.width, 300)
        XCTAssertEqual(image.height, 150)
    }

    func test_downsample_whenDataIsNotAnImage_returnsNil() {
        XCTAssertNil(ImageDownsampler.downsample(Data("not an image".utf8), filling: CGSize(width: 100, height: 100)))
    }

    // MARK: - APODWidgetContentLoader

    func test_widgetLoader_withImageEntry_downsamplesScreenSizedImage() async throws {
        let entry = makeEntry(media: .image(url: Self.screenImageURL, hdURL: Self.originalImageURL))
        let imageData = try makePNGData(width: 600, height: 400)
        let requests = RequestLog()
        let loader = APODWidgetContentLoader(repository: StubAPODRepository(result: .success(entry))) { url in
            await requests.record(url)
            return imageData
        }
        let now = try utcDate("2026-10-21T19:00:00Z")

        let update = await loader.load(now: now, imagePixelSize: CGSize(width: 200, height: 100))

        let content = try XCTUnwrap(update.content)
        guard case let .image(image) = content.media else {
            return XCTFail("Expected an image")
        }
        XCTAssertEqual(content.title, "Nebula")
        XCTAssertEqual(content.displayDate, entry.displayDate)
        XCTAssertEqual(image.cgImage?.width, 200)
        XCTAssertEqual(image.cgImage?.height, 100)
        // Neither the multi-megabyte original nor the article page (`shareURL`).
        let requestedURLs = await requests.urls
        XCTAssertEqual(requestedURLs, [Self.screenImageURL])
        XCTAssertEqual(update.nextRefresh, APODPublicationSchedule.nextPublication(after: now))
    }

    func test_widgetLoader_withRecordFromSource_requestsScreenWidthCopyOfOriginal() async throws {
        let record = APODRecord(
            id: "2026-10-21",
            title: "Nebula",
            explanation: "A bright nebula.",
            credit: nil,
            pageURL: Self.pageURL,
            imageURL: Self.originalImageURL,
            videoURL: nil
        )
        let requests = RequestLog()
        let imageData = try makePNGData(width: 600, height: 400)
        let loader = APODWidgetContentLoader(repository: StubAPODRepository(result: .success(APODEntry(record: record)))) { url in
            await requests.record(url)
            return imageData
        }

        _ = await loader.load(now: try utcDate("2026-10-21T19:00:00Z"), imagePixelSize: CGSize(width: 200, height: 100))

        let requestedURLs = await requests.urls
        XCTAssertEqual(requestedURLs, [APODImageURL.resized(Self.originalImageURL, width: APODEntry.screenImageWidth)])
    }

    func test_widgetLoader_withVideoEntry_showsScreenWidthPosterAndCredit() async throws {
        let entry = makeEntry(
            media: .video(try XCTUnwrap(URL(string: "https://www.youtube.com/embed/launch"))),
            copyright: "Jane Doe",
            thumbnailURL: APODImageURL.resized(Self.originalImageURL, width: APODEntry.thumbnailWidth)
        )
        let imageData = try makePNGData(width: 600, height: 400)
        let requests = RequestLog()
        let loader = APODWidgetContentLoader(repository: StubAPODRepository(result: .success(entry))) { url in
            await requests.record(url)
            return imageData
        }

        let update = await loader.load(now: try utcDate("2026-10-21T19:00:00Z"), imagePixelSize: CGSize(width: 200, height: 100))

        let content = try XCTUnwrap(update.content)
        guard case let .image(image) = content.media else {
            return XCTFail("Expected the poster")
        }
        XCTAssertEqual(image.cgImage?.width, 200)
        XCTAssertTrue(content.isVideo)
        XCTAssertEqual(content.credit, "Jane Doe")
        // The poster at screen width, not the 480 px list thumbnail.
        let requestedURLs = await requests.urls
        XCTAssertEqual(requestedURLs, [Self.screenImageURL])
    }

    func test_widgetLoader_withImageEntryWithoutCredit_creditsNASA() async throws {
        let entry = makeEntry(media: .image(url: Self.screenImageURL, hdURL: nil))
        let imageData = try makePNGData(width: 600, height: 400)
        let loader = APODWidgetContentLoader(repository: StubAPODRepository(result: .success(entry))) { _ in imageData }

        let update = await loader.load(now: try utcDate("2026-10-21T19:00:00Z"), imagePixelSize: CGSize(width: 200, height: 100))

        let content = try XCTUnwrap(update.content)
        XCTAssertEqual(content.credit, "NASA")
        XCTAssertFalse(content.isVideo)
    }

    func test_widgetLoader_withVideoEntryWithoutPoster_opensInAppWithoutDownloading() async throws {
        let entry = makeEntry(media: .video(try XCTUnwrap(URL(string: "https://www.youtube.com/embed/launch"))))
        let requests = RequestLog()
        let loader = APODWidgetContentLoader(repository: StubAPODRepository(result: .success(entry))) { url in
            await requests.record(url)
            return Data()
        }

        let update = await loader.load(now: try utcDate("2026-10-21T19:00:00Z"), imagePixelSize: CGSize(width: 200, height: 100))

        let content = try XCTUnwrap(update.content)
        guard case .openInApp = content.media else {
            return XCTFail("Expected openInApp media")
        }
        XCTAssertTrue(content.isVideo)
        let requestedURLs = await requests.urls
        XCTAssertTrue(requestedURLs.isEmpty)
    }

    func test_widgetLoader_whenFetchOrImageFails_returnsNoContentAndRetries() async throws {
        let now = try utcDate("2026-10-21T19:00:00Z")
        let imageEntry = makeEntry(media: .image(url: Self.screenImageURL, hdURL: nil))
        let failingFetch = APODWidgetContentLoader(repository: StubAPODRepository(result: .failure(NASAAPIError.offline))) { _ in Data() }
        let brokenImage = APODWidgetContentLoader(repository: StubAPODRepository(result: .success(imageEntry))) { _ in
            Data("not an image".utf8)
        }

        let fetchUpdate = await failingFetch.load(now: now, imagePixelSize: CGSize(width: 200, height: 100))
        let imageUpdate = await brokenImage.load(now: now, imagePixelSize: CGSize(width: 200, height: 100))

        let retry = now.addingTimeInterval(APODPublicationSchedule.retryInterval)
        XCTAssertNil(fetchUpdate.content)
        XCTAssertEqual(fetchUpdate.nextRefresh, retry)
        XCTAssertNil(imageUpdate.content)
        XCTAssertEqual(imageUpdate.nextRefresh, retry)
    }

    // MARK: - Helpers

    private static let originalImageURL = URL(string: "https://assets.science.nasa.gov/content/dam/science/cds/apod/2026/10/nebula.jpg")!
    private static let screenImageURL = URL(string: "https://assets.science.nasa.gov/content/dam/science/cds/apod/2026/10/nebula.jpg?w=1280&fit=clip")!
    private static let pageURL = URL(string: "https://science.nasa.gov/image-article/nebula/")!

    private func makeEntry(media: APODEntry.Media, copyright: String? = nil, thumbnailURL: URL? = nil) -> APODEntry {
        APODEntry(
            id: "2026-10-21",
            title: "Nebula",
            explanation: "A bright nebula.",
            date: APODEntry.apiFormatter.date(from: "2026-10-21") ?? .now,
            copyright: copyright,
            media: media,
            shareURL: Self.pageURL,
            thumbnailURL: thumbnailURL
        )
    }

    private func utcDate(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }
}

private struct StubAPODRepository: APODRepositoryProtocol {
    let result: Result<APODEntry, Error>

    func fetchToday() async throws -> APODEntry {
        try result.get()
    }

    func fetch(date: Date) async throws -> APODEntry {
        try result.get()
    }
}

private actor RequestLog {
    private(set) var urls: [URL] = []

    func record(_ url: URL) {
        urls.append(url)
    }
}
