import Foundation

struct NASAClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func fetch<T: Decodable>(_ type: T.Type, endpoint: NASAEndpoint) async throws -> T {
        let request = try NASARequestBuilder.makeURLRequest(for: endpoint)

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
