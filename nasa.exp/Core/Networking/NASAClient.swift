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
        return try await fetch(type, request: request)
    }

    /// Fetches and decodes a resource from an arbitrary public NASA URL that needs no API key
    /// (for example the Mars raw image feeds hosted on `mars.nasa.gov`).
    func fetch<T: Decodable>(_ type: T.Type, url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        return try await fetch(type, request: request)
    }

    private func fetch<T: Decodable>(_ type: T.Type, request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NASAAPIError.transportError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NASAAPIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NASAAPIError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw NASAAPIError.decodingError(error)
        }
    }
}
