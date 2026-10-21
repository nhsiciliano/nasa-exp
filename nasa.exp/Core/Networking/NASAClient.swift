import Foundation

nonisolated struct NASAClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    /// Fetches and decodes a resource from `api.nasa.gov`, attaching the configured API key.
    func fetch<T: Decodable>(_ type: T.Type, endpoint: NASAEndpoint) async throws -> T {
        let request = try NASARequestBuilder.makeURLRequest(for: endpoint)
        return try await fetch(type, request: request, usesAPIKey: true)
    }

    /// Fetches and decodes a resource from an arbitrary public NASA URL that needs no API key
    /// (for example the Mars raw image feeds hosted on `mars.nasa.gov`).
    func fetch<T: Decodable>(_ type: T.Type, url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        return try await fetch(type, request: request, usesAPIKey: false)
    }

    private func fetch<T: Decodable>(_ type: T.Type, request: URLRequest, usesAPIKey: Bool) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where Self.offlineErrorCodes.contains(error.code) {
            throw NASAAPIError.offline
        } catch {
            throw NASAAPIError.transportError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NASAAPIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 429:
            let retryAfter = Self.retryAfterInterval(from: httpResponse.value(forHTTPHeaderField: "Retry-After"))
            throw NASAAPIError.rateLimited(retryAfter: retryAfter)
        // Only `api.nasa.gov` uses a key; a 403 from the public feeds means something else.
        case 403 where usesAPIKey:
            throw NASAAPIError.invalidAPIKey
        default:
            throw NASAAPIError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NASAAPIError.decodingError(error)
        }
    }

    private static let offlineErrorCodes: Set<URLError.Code> = [
        .notConnectedToInternet,
        .networkConnectionLost,
        .timedOut
    ]

    /// Parses an HTTP `Retry-After` value, which can be either delay seconds or an HTTP date.
    static func retryAfterInterval(from headerValue: String?, now: Date = .now) -> TimeInterval? {
        guard let value = headerValue?.trimmingCharacters(in: .whitespaces), !value.isEmpty else {
            return nil
        }

        if let seconds = TimeInterval(value) {
            return max(0, seconds)
        }

        guard let date = httpDateFormatter.date(from: value) else {
            return nil
        }

        return max(0, date.timeIntervalSince(now))
    }

    private static let httpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter
    }()
}
