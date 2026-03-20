import Foundation

enum NASARequestBuilder {
    static func makeURLRequest(for endpoint: NASAEndpoint) throws -> URLRequest {
        guard NASAEnvironment.hasValidAPIKey else {
            throw NASAAPIError.missingAPIKey
        }

        var components = URLComponents(
            url: NASAEnvironment.apiBaseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = endpoint.queryItems

        guard let url = components?.url else {
            throw NASAAPIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        return request
    }
}
