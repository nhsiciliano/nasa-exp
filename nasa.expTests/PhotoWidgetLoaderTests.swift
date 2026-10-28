import CoreGraphics
import Foundation
import XCTest
@testable import nasa_exp

/// Loaders of the Rovers and EPIC widgets, fed with the real responses in `docs/fixtures`.
@MainActor
final class PhotoWidgetLoaderTests: XCTestCase {
    // MARK: - Rovers

    func test_roversLoader_requestsOnePhotoPerRoverAndShowsTheNewest() async throws {
        let server = try StubServer([
            Self.perseveranceFeedURL: .success(fixture("rovers-mars2020-sample.json")),
            Self.curiosityFeedURL: .success(fixture("rovers-msl-sample.json")),
            Self.curiosityImageURL: .success(makePNGData(width: 600, height: 400))
        ])
        let loader = RoversWidgetContentLoader(loadData: server.loadData)
        let now = try utcDate("2026-10-21T12:00:00Z")

        let update = await loader.load(now: now, imagePixelSize: CGSize(width: 200, height: 100))

        // Curiosity's fixture photo (21:39Z) is an hour newer than Perseverance's (20:33Z).
        let content = try XCTUnwrap(update.content)
        XCTAssertEqual(content.roverName, "Curiosity")
        XCTAssertEqual(content.cameraName, "ChemCam")
        XCTAssertTrue(content.detail.hasPrefix("Sol 5050 · "))
        XCTAssertEqual(content.credit, "NASA/JPL-Caltech/LANL/CNES/CNRS/IRAP/IAS/LPG")
        XCTAssertEqual(content.image?.cgImage?.width, 200)
        XCTAssertEqual(content.image?.cgImage?.height, 100)
        XCTAssertEqual(update.nextRefresh, now.addingTimeInterval(PhotoWidgetSchedule.refreshInterval))

        let requested = await server.requestedURLs
        XCTAssertEqual(Set(requested), [Self.perseveranceFeedURL, Self.curiosityFeedURL, Self.curiosityImageURL])
        XCTAssertTrue(Self.perseveranceFeedURL.absoluteString.contains("num=1"))
        XCTAssertTrue(Self.curiosityFeedURL.absoluteString.contains("per_page=1"))
    }

    func test_roversLoader_whenOneFeedTimesOut_showsTheOtherRover() async throws {
        let server = try StubServer([
            Self.perseveranceFeedURL: .success(fixture("rovers-mars2020-sample.json")),
            Self.curiosityFeedURL: .failure(NASAAPIError.offline),
            Self.perseveranceImageURL: .success(makePNGData(width: 600, height: 400))
        ])
        let loader = RoversWidgetContentLoader(loadData: server.loadData)

        let update = await loader.load(now: try utcDate("2026-10-21T12:00:00Z"), imagePixelSize: CGSize(width: 200, height: 100))

        let content = try XCTUnwrap(update.content)
        XCTAssertEqual(content.roverName, "Perseverance")
        XCTAssertEqual(content.cameraName, "PIXL")
        XCTAssertEqual(content.credit, "NASA/JPL-Caltech")
        let requested = await server.requestedURLs
        XCTAssertTrue(requested.contains(Self.perseveranceImageURL), "Uses the 1200 px `large` file, not the full-res PNG")
    }

    func test_roversLoader_whenBothFeedsOrTheImageFail_returnsNoContentAndRetries() async throws {
        let now = try utcDate("2026-10-21T12:00:00Z")
        let bothDown = RoversWidgetContentLoader(loadData: StubServer([:]).loadData)
        let brokenImage = RoversWidgetContentLoader(loadData: try StubServer([
            Self.curiosityFeedURL: .success(fixture("rovers-msl-sample.json")),
            Self.curiosityImageURL: .success(Data("not an image".utf8))
        ]).loadData)

        let downUpdate = await bothDown.load(now: now, imagePixelSize: CGSize(width: 200, height: 100))
        let imageUpdate = await brokenImage.load(now: now, imagePixelSize: CGSize(width: 200, height: 100))

        let retry = now.addingTimeInterval(PhotoWidgetSchedule.retryInterval)
        XCTAssertNil(downUpdate.content)
        XCTAssertEqual(downUpdate.nextRefresh, retry)
        XCTAssertNil(imageUpdate.content)
        XCTAssertEqual(imageUpdate.nextRefresh, retry)
    }

    // MARK: - EPIC

    func test_epicLoader_requestsKeylessFeedAndJPEGOfLatestImage() async throws {
        let server = try StubServer([
            EPICWidgetContentLoader.latestURL: .success(fixture("epic-gsfc-natural-sample.json")),
            Self.epicLatestJPEGURL: .success(makePNGData(width: 400, height: 400))
        ])
        let loader = EPICWidgetContentLoader(loadData: server.loadData)
        let now = try utcDate("2026-10-27T12:00:00Z")

        let update = await loader.load(now: now, imagePixelSize: CGSize(width: 150, height: 150))

        let content = try XCTUnwrap(update.content)
        XCTAssertEqual(content.credit, "NASA EPIC Team")
        XCTAssertEqual(content.image?.cgImage?.width, 150)
        XCTAssertEqual(update.nextRefresh, now.addingTimeInterval(PhotoWidgetSchedule.refreshInterval))

        let requested = await server.requestedURLs
        // The day's last frame (22:26), as the 1080 px JPEG; no `api.nasa.gov` and no key anywhere.
        XCTAssertEqual(requested, [EPICWidgetContentLoader.latestURL, Self.epicLatestJPEGURL])
        XCTAssertFalse(requested.contains { $0.host == "api.nasa.gov" || $0.query?.contains("api_key") == true })
    }

    func test_epicLoader_whenFeedIsEmptyOrFails_returnsNoContentAndRetries() async throws {
        let now = try utcDate("2026-10-27T12:00:00Z")
        let empty = EPICWidgetContentLoader(loadData: StubServer([
            EPICWidgetContentLoader.latestURL: .success(Data("[]".utf8))
        ]).loadData)
        let failing = EPICWidgetContentLoader(loadData: StubServer([:]).loadData)

        let emptyUpdate = await empty.load(now: now, imagePixelSize: CGSize(width: 150, height: 150))
        let failingUpdate = await failing.load(now: now, imagePixelSize: CGSize(width: 150, height: 150))

        XCTAssertNil(emptyUpdate.content)
        XCTAssertEqual(emptyUpdate.nextRefresh, now.addingTimeInterval(PhotoWidgetSchedule.retryInterval))
        XCTAssertNil(failingUpdate.content)
        XCTAssertEqual(failingUpdate.nextRefresh, now.addingTimeInterval(PhotoWidgetSchedule.retryInterval))
    }

    func test_epicEntry_jpegURL_pointsToTheJPGFolderOfTheSameFrame() throws {
        let entries = try NASAClient.decode([EPICEntryDTO].self, from: fixture("epic-gsfc-natural-sample.json"))
            .map(EPICEntry.init(dto:))

        XCTAssertEqual(entries.last?.jpegURL, Self.epicLatestJPEGURL)
        XCTAssertEqual(
            entries.last?.imageURL?.absoluteString,
            "https://epic.gsfc.nasa.gov/archive/natural/2026/10/26/png/epic_1b_20261026223145.png"
        )
    }

    // MARK: - Helpers

    private static let perseveranceFeedURL = MarsRawImagesRequest(rover: .perseverance, sol: nil, camera: .all, page: 0, pageSize: 1).url!
    private static let curiosityFeedURL = MarsRawImagesRequest(rover: .curiosity, sol: nil, camera: .all, page: 0, pageSize: 1).url!
    private static let perseveranceImageURL = URL(string: "https://mars.nasa.gov/mars2020-raw-images/pub/ods/surface/sol/02015/ids/edr/browse/pixl/PCW_2015_0845798916_000ECM_N09200007670993971688075J01_1200.jpg")!
    private static let curiosityImageURL = URL(string: "https://mars.nasa.gov/msl-raw-images/proj/msl/redops/ods/surface/sol/05050/opgs/edr/ccam/CR0_845799994EDR_F1251326CCAM01050M_.JPG")!
    private static let epicLatestJPEGURL = URL(string: "https://epic.gsfc.nasa.gov/archive/natural/2026/10/26/jpg/epic_1b_20261026223145.jpg")!

    private func fixture(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures/\(name)")
        return try Data(contentsOf: url)
    }

    private func utcDate(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }
}

/// Answers each URL with its canned result and records the requests; unknown URLs fail like a
/// dropped connection.
private actor StubServer {
    private let responses: [URL: Result<Data, Error>]
    private(set) var requestedURLs: [URL] = []

    init(_ responses: [URL: Result<Data, Error>]) {
        self.responses = responses
    }

    nonisolated var loadData: @Sendable (URL) async throws -> Data {
        { url in try await self.respond(to: url) }
    }

    private func respond(to url: URL) throws -> Data {
        requestedURLs.append(url)
        guard let response = responses[url] else {
            throw NASAAPIError.offline
        }
        return try response.get()
    }
}
