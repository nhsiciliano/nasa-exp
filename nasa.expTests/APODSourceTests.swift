import Foundation
import XCTest
@testable import nasa_exp

final class APODSourceTests: XCTestCase {
    override func tearDown() {
        APODStubURLProtocol.reset()
        super.tearDown()
    }

    // MARK: - RSS feed

    func test_feedParser_readsRecordsNewestFirstWithEasternDayIDs() throws {
        let records = try APODFeedParser.records(from: fixture("apod-basic-sample.xml"))

        XCTAssertEqual(records.map(\.id), ["2026-10-21", "2026-10-19", "2026-10-18"])
    }

    func test_feedParser_mapsImageEntryToPlainTextAndOriginalImage() throws {
        let record = try XCTUnwrap(APODFeedParser.records(from: fixture("apod-basic-sample.xml")).first)

        XCTAssertEqual(record.title, "New Ghosts Revealed in Cassiopeia")
        XCTAssertTrue(record.explanation.hasPrefix("Jinkies, look at all those ghosts! It took 100 hours of observation"))
        XCTAssertFalse(record.explanation.contains("<"))
        XCTAssertFalse(record.explanation.contains("Tomorrow"))
        XCTAssertEqual(record.credit, "Louis Leroux-Géré, Thibault Rouillée, Vincent Martin, Cédric de Decker (Starfront Observatories)")
        XCTAssertEqual(
            record.pageURL?.absoluteString,
            "https://science.nasa.gov/image-article/apod-2026-october-21-new-ghosts-revealed-in-cassiopeia/"
        )
        XCTAssertEqual(
            record.imageURL?.absoluteString,
            "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/IC63.png"
        )
        XCTAssertNil(record.videoURL)
    }

    func test_feedParser_dropsRepeatedExplanationLabelAndIgnoresLinkedVideoFiles() throws {
        let record = try APODFeedParser.records(from: fixture("apod-basic-sample.xml"))[1]

        XCTAssertTrue(record.explanation.hasPrefix("What is Treble Clef?"))
        // The explanation links to .mp4 files, but the entry itself is an image.
        XCTAssertNil(record.videoURL)
        XCTAssertNotNil(record.imageURL)
    }

    func test_feedParser_mapsIframeEntryToVideoWithPoster() throws {
        let record = try APODFeedParser.records(from: fixture("apod-basic-sample.xml"))[2]
        let entry = APODEntry(record: record)

        XCTAssertEqual(record.videoURL?.absoluteString, "https://www.youtube.com/embed/DzrCEm1ZBRY?rel=0")
        XCTAssertEqual(
            record.credit,
            "NASA, ESA, & The Hubble Heritage Project (STScI/AURA); Sonification: NASA, CXC, SAO, K. Arcand, M. Russo & A. Santaguida"
        )
        guard case let .video(url) = entry.media else {
            return XCTFail("Expected video media")
        }
        XCTAssertEqual(url, record.videoURL)
        XCTAssertEqual(
            entry.thumbnailURL?.absoluteString,
            "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/SonifiedEagleNebulaPillars.jpg?w=480&fit=clip"
        )
    }

    // MARK: - WordPress archive

    func test_archivePost_videoDay_mapsEmbedPosterAndCredit() throws {
        let record = try XCTUnwrap(archiveRecords()["2026-10-18"])

        XCTAssertEqual(record.title, "Sonified: Eagle Nebula Pillars")
        XCTAssertTrue(record.explanation.hasPrefix("Yes, but have you ever experienced the Eagle Nebula with your ears?"))
        XCTAssertFalse(record.explanation.contains("Tomorrow"))
        XCTAssertEqual(
            record.credit,
            "NASA, ESA, & The Hubble Heritage Project (STScI/AURA); Sonification: NASA, CXC, SAO, K. Arcand, M. Russo & A. Santaguida"
        )
        XCTAssertEqual(record.videoURL?.absoluteString, "https://www.youtube.com/embed/DzrCEm1ZBRY?feature=oembed")
        XCTAssertEqual(
            record.imageURL?.absoluteString,
            "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/SonifiedEagleNebulaPillars.jpg"
        )
    }

    func test_archivePost_oldEntry_stripsCreditLabelAndCleansText() throws {
        let record = try XCTUnwrap(archiveRecords()["2004-05-01"])

        XCTAssertEqual(record.title, "A Western Sky at Twilight")
        XCTAssertEqual(record.credit, "Stan Richard")
        XCTAssertTrue(record.explanation.hasPrefix("On April 23rd, the Moon along with planets Saturn, Mars, and Venus"))
        XCTAssertTrue(record.explanation.contains("…"))
        XCTAssertTrue(record.explanation.hasSuffix("good month for comets."))
        XCTAssertEqual(
            record.imageURL?.absoluteString,
            "https://assets.science.nasa.gov/content/dam/science/cds/apod/apod/2004/may/mvms_042304_richard_f2.jpg"
        )
        XCTAssertNil(record.videoURL)
    }

    func test_archivePost_withPlaceholderFeaturedImage_usesPageImage() throws {
        let record = try XCTUnwrap(archiveRecords()["1995-06-16"])

        XCTAssertEqual(record.title, "Neutron Star Earth")
        XCTAssertNil(record.credit)
        XCTAssertEqual(
            record.imageURL?.absoluteString,
            "https://assets.science.nasa.gov/content/dam/science/cds/apod/apod/1995/june/e_lens.gif"
        )
        XCTAssertNil(record.videoURL)
    }

    // MARK: - Text and URLs

    func test_htmlText_dropsTagsDecodesEntitiesAndCollapsesWhitespace() {
        let html = "<strong>A</strong>&nbsp;&amp; B&#8217;s <a href=\"x\">link</a>\n<br/>end &#x2013; done ( <a>x</a> ) ."

        XCTAssertEqual(HTMLText.plainText(html), "A & B’s link end – done (x).")
    }

    func test_extractor_stripsCreditLabelsAndTitlePrefix() {
        XCTAssertEqual(APODHTMLExtractor.credit(fromHTML: "Image Credit &amp; Copyright: <a href=\"x\">Jane Doe</a>"), "Jane Doe")
        XCTAssertEqual(APODHTMLExtractor.credit(fromHTML: "X-ray: NASA/CXC; Radio: LOFAR"), "X-ray: NASA/CXC; Radio: LOFAR")
        XCTAssertNil(APODHTMLExtractor.credit(fromHTML: "  "))
        XCTAssertEqual(APODHTMLExtractor.title(fromHTML: "APOD: 2026 October 21 &#8211; New Ghosts"), "New Ghosts")
    }

    func test_apodDay_usesNewYorkCalendarDay() throws {
        XCTAssertEqual(APODDay.id(for: try utcDate("2026-10-21T04:05:00Z")), "2026-10-21")
        XCTAssertEqual(APODDay.id(for: try utcDate("2026-10-21T03:59:00Z")), "2026-10-20")
        XCTAssertEqual(APODDay.id("2026-03-01", offsetBy: -1), "2026-02-28")
        XCTAssertEqual(APODDay.days(from: "2026-09-22", to: "2026-10-21"), 29)
    }

    func test_archivePostURL_coversWholeDayWithExclusiveAfterBound() throws {
        let url = try XCTUnwrap(APODSource.archivePostURL(for: "2004-05-01"))
        let query = queryItems(of: url)

        XCTAssertEqual(url.host, "science.nasa.gov")
        XCTAssertEqual(url.path, "/wp-json/wp/v2/image-article")
        XCTAssertEqual(query["categories"], "22766")
        XCTAssertEqual(query["after"], "2004-04-30T23:59:59")
        XCTAssertEqual(query["before"], "2004-05-01T23:59:59")
    }

    func test_imageURL_resizesOnlyCDNImages() throws {
        let cdn = try XCTUnwrap(URL(string: "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/IC63.png?w=2622&h=1751&fit=clip"))
        let other = try XCTUnwrap(URL(string: "https://example.com/apod.jpg"))

        XCTAssertEqual(APODImageURL.resized(cdn, width: 1280).absoluteString, "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/IC63.png?w=1280&fit=clip")
        XCTAssertEqual(APODImageURL.original(cdn).absoluteString, "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/IC63.png")
        XCTAssertEqual(APODImageURL.resized(other, width: 1280), other)
        XCTAssertTrue(APODImageURL.isAPODImage(cdn))
        XCTAssertFalse(APODImageURL.isAPODImage(try XCTUnwrap(URL(string: "https://assets.science.nasa.gov/dynamicimage/assets/science/astro/programs/cosmic-origins/images/misc/news-thumbnail.png"))))
    }

    // MARK: - Repository

    func test_repositoryFetchToday_readsNewestFeedEntry() async throws {
        let feed = try fixture("apod-basic-sample.xml")
        APODStubURLProtocol.respond { url in url == APODSource.feedURL ? (200, feed) : (404, Data()) }

        let entry = try await makeRepository().fetchToday()

        XCTAssertEqual(entry.id, "2026-10-21")
        XCTAssertEqual(entry.date, APODEntry.apiFormatter.date(from: "2026-10-21"))
        XCTAssertEqual(
            entry.shareURL?.absoluteString,
            "https://science.nasa.gov/image-article/apod-2026-october-21-new-ghosts-revealed-in-cassiopeia/"
        )
        guard case let .image(url, hdURL) = entry.media else {
            return XCTFail("Expected image media")
        }
        XCTAssertEqual(url.absoluteString, "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/IC63.png?w=1280&fit=clip")
        XCTAssertEqual(hdURL?.absoluteString, "https://assets.science.nasa.gov/dynamicimage/assets/science/cds/apod/apod/2026/october/IC63.png")
    }

    func test_repositoryFetchDate_withinFeedWindow_reusesCachedFeed() async throws {
        let feed = try fixture("apod-basic-sample.xml")
        APODStubURLProtocol.respond { url in url == APODSource.feedURL ? (200, feed) : (404, Data()) }
        let repository = makeRepository()

        _ = try await repository.fetchToday()
        let entry = try await repository.fetch(date: try localDay(2026, 10, 18))

        XCTAssertEqual(entry.id, "2026-10-18")
        guard case .video = entry.media else {
            return XCTFail("Expected video media")
        }
        XCTAssertEqual(APODStubURLProtocol.requestedURLs.count, 1)
    }

    func test_repositoryFetchDate_olderThanFeed_queriesArchiveForThatDay() async throws {
        let post = try archiveResponse(for: "2004-05-01")
        APODStubURLProtocol.respond { url in url.path == "/wp-json/wp/v2/image-article" ? (200, post) : (404, Data()) }

        let entry = try await makeRepository().fetch(date: try localDay(2004, 5, 1))

        XCTAssertEqual(entry.id, "2004-05-01")
        XCTAssertEqual(entry.copyright, "Stan Richard")
        let requested = try XCTUnwrap(APODStubURLProtocol.requestedURLs.first)
        XCTAssertEqual(APODStubURLProtocol.requestedURLs.count, 1)
        XCTAssertEqual(queryItems(of: requested)["before"], "2004-05-01T23:59:59")
    }

    func test_repositoryFetchDate_whenArchiveHasNoPost_throwsNotFound() async throws {
        APODStubURLProtocol.respond { _ in (200, Data("[]".utf8)) }

        do {
            _ = try await makeRepository().fetch(date: try localDay(1995, 6, 17))
            XCTFail("Expected notFound")
        } catch NASAAPIError.notFound {
            // Expected: 1995-06-17 is one of the few days without an APOD.
        }
    }

    func test_repositoryFetchToday_whenFeedFails_fallsBackToNewestArchivePost() async throws {
        let post = try archiveResponse(for: "2026-10-18")
        APODStubURLProtocol.respond { url in url == APODSource.feedURL ? (500, Data()) : (200, post) }

        let entry = try await makeRepository().fetchToday()

        XCTAssertEqual(entry.id, "2026-10-18")
        XCTAssertEqual(queryItems(of: try XCTUnwrap(APODStubURLProtocol.requestedURLs.last))["order"], "desc")
    }

    // MARK: - Helpers

    private func makeRepository() -> APODRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [APODStubURLProtocol.self]
        let now = Date(timeIntervalSince1970: 1_792_594_800) // 2026-10-21T15:00:00Z
        return APODRepository(
            client: NASAClient(session: URLSession(configuration: configuration)),
            feedCache: APODFeedCache(),
            now: { now }
        )
    }

    private func fixture(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("docs/fixtures/\(name)")
        return try Data(contentsOf: url)
    }

    private func archivePosts() throws -> [[String: Any]] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: fixture("apod-wp-sample.json")) as? [[String: Any]])
    }

    private func archiveRecords() throws -> [String: APODRecord] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let posts = try decoder.decode([APODArchivePostDTO].self, from: fixture("apod-wp-sample.json"))
        let records = posts.compactMap(APODRecord.init(post:))
        return Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0) })
    }

    /// The WordPress response for a day query: an array with that day's post.
    private func archiveResponse(for id: String) throws -> Data {
        let post = try XCTUnwrap(archivePosts().first { ($0["date"] as? String)?.hasPrefix(id) == true })
        return try JSONSerialization.data(withJSONObject: [post])
    }

    private func queryItems(of url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { first, _ in first })
    }

    private func localDay(_ year: Int, _ month: Int, _ day: Int) throws -> Date {
        try XCTUnwrap(Calendar.current.date(from: DateComponents(year: year, month: month, day: day)))
    }

    private func utcDate(_ value: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: value))
    }
}

/// Serves canned responses by URL and records every request it sees.
private final class APODStubURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var responder: ((URL) -> (statusCode: Int, body: Data))?
    nonisolated(unsafe) private(set) static var requestedURLs: [URL] = []

    static func respond(with responder: @escaping (URL) -> (statusCode: Int, body: Data)) {
        self.responder = responder
        requestedURLs = []
    }

    static func reset() {
        responder = nil
        requestedURLs = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url, let responder = Self.responder else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        Self.requestedURLs.append(url)
        let (statusCode, body) = responder(url)
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
