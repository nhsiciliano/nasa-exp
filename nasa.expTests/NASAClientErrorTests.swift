import Foundation
import XCTest
@testable import nasa_exp

final class NASAClientErrorTests: XCTestCase {
    private let feedURL = URL(string: "https://mars.nasa.gov/api/v1/raw_image_items/")!

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func test_fetch_whenStatusIs429WithRetryAfterSeconds_throwsRateLimitedWithDelay() async {
        MockURLProtocol.handler = { request in
            (Self.response(for: request, statusCode: 429, headers: ["Retry-After": "120"]), Data())
        }

        let error = await fetchError { try await $0.fetch(EmptyPayload.self, url: self.feedURL) }

        guard case let .rateLimited(retryAfter) = error else {
            return XCTFail("Expected rateLimited, got \(String(describing: error))")
        }

        XCTAssertEqual(retryAfter, 120)
        XCTAssertEqual(error?.errorDescription, "Demasiadas consultas a NASA. Probá de nuevo en 2 minutos.")
    }

    func test_fetch_whenStatusIs429WithoutRetryAfter_throwsRateLimitedWithGenericMessage() async {
        MockURLProtocol.handler = { request in
            (Self.response(for: request, statusCode: 429), Data())
        }

        let error = await fetchError { try await $0.fetch(APODResponseDTO.self, endpoint: .apod(date: nil)) }

        guard case let .rateLimited(retryAfter) = error else {
            return XCTFail("Expected rateLimited, got \(String(describing: error))")
        }

        XCTAssertNil(retryAfter)
        XCTAssertEqual(error?.errorDescription, "Demasiadas consultas a NASA. Probá de nuevo en unos minutos.")
    }

    func test_fetch_whenAPIKeyEndpointReturns403_throwsInvalidAPIKey() async {
        MockURLProtocol.handler = { request in
            (Self.response(for: request, statusCode: 403), Data(#"{"error":{"code":"API_KEY_INVALID"}}"#.utf8))
        }

        let error = await fetchError { try await $0.fetch(APODResponseDTO.self, endpoint: .apod(date: nil)) }

        guard case .invalidAPIKey = error else {
            return XCTFail("Expected invalidAPIKey, got \(String(describing: error))")
        }
    }

    func test_fetch_whenKeylessFeedReturns403_throwsServerError() async {
        MockURLProtocol.handler = { request in
            (Self.response(for: request, statusCode: 403), Data())
        }

        let error = await fetchError { try await $0.fetch(EmptyPayload.self, url: self.feedURL) }

        guard case .serverError(statusCode: 403) = error else {
            return XCTFail("Expected serverError(403), got \(String(describing: error))")
        }
    }

    func test_fetch_whenNotConnectedToInternet_throwsOffline() async {
        for code in [URLError.Code.notConnectedToInternet, .networkConnectionLost, .timedOut] {
            MockURLProtocol.handler = { _ in throw URLError(code) }

            let error = await fetchError { try await $0.fetch(EmptyPayload.self, url: self.feedURL) }

            guard case .offline = error else {
                return XCTFail("Expected offline for \(code), got \(String(describing: error))")
            }
        }
    }

    func test_fetch_whenOtherURLError_throwsTransportError() async {
        MockURLProtocol.handler = { _ in throw URLError(.cannotFindHost) }

        let error = await fetchError { try await $0.fetch(EmptyPayload.self, url: self.feedURL) }

        guard case .transportError = error else {
            return XCTFail("Expected transportError, got \(String(describing: error))")
        }
    }

    func test_fetch_whenStatusIs500_throwsServerError() async {
        MockURLProtocol.handler = { request in
            (Self.response(for: request, statusCode: 500), Data())
        }

        let error = await fetchError { try await $0.fetch(EmptyPayload.self, url: self.feedURL) }

        guard case .serverError(statusCode: 500) = error else {
            return XCTFail("Expected serverError(500), got \(String(describing: error))")
        }
    }

    func test_retryAfterInterval_parsesSecondsAndHTTPDate() {
        let now = Date(timeIntervalSince1970: 1_000_000)

        XCTAssertEqual(NASAClient.retryAfterInterval(from: "30", now: now), 30)
        XCTAssertEqual(NASAClient.retryAfterInterval(from: "Mon, 12 Jan 1970 13:40:00 GMT", now: now), 0)
        XCTAssertEqual(NASAClient.retryAfterInterval(from: "Mon, 12 Jan 1970 13:48:40 GMT", now: now), 120)
        XCTAssertNil(NASAClient.retryAfterInterval(from: nil, now: now))
        XCTAssertNil(NASAClient.retryAfterInterval(from: "soon", now: now))
    }

    // MARK: - Helpers

    private func fetchError(
        _ operation: (NASAClient) async throws -> Any
    ) async -> NASAAPIError? {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let client = NASAClient(session: URLSession(configuration: configuration))

        do {
            _ = try await operation(client)
            XCTFail("Expected the request to throw")
            return nil
        } catch let error as NASAAPIError {
            return error
        } catch {
            XCTFail("Expected NASAAPIError, got \(error)")
            return nil
        }
    }

    private static func response(
        for request: URLRequest,
        statusCode: Int,
        headers: [String: String] = [:]
    ) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: headers)!
    }
}

private struct EmptyPayload: Decodable {}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
