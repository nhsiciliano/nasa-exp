import Foundation

/// Endpoints on `api.nasa.gov`. APOD left this API in 2026 (see `APODSource`).
nonisolated enum NASAEndpoint {
    case epicNatural(date: String)
    case epicLatest

    var path: String {
        switch self {
        case let .epicNatural(date):
            return "/EPIC/api/natural/date/\(date)"
        case .epicLatest:
            return "/EPIC/api/natural"
        }
    }

    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "api_key", value: NASAEnvironment.apiKey)]
    }
}
