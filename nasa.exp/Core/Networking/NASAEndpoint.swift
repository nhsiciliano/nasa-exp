import Foundation

nonisolated enum NASAEndpoint {
    case apod(date: String?)
    case epicNatural(date: String)
    case epicLatest

    var path: String {
        switch self {
        case .apod:
            return "/planetary/apod"
        case let .epicNatural(date):
            return "/EPIC/api/natural/date/\(date)"
        case .epicLatest:
            return "/EPIC/api/natural"
        }
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []

        switch self {
        case let .apod(date):
            if let date {
                items.append(URLQueryItem(name: "date", value: date))
            }

        case .epicNatural, .epicLatest:
            break
        }

        items.append(URLQueryItem(name: "api_key", value: NASAEnvironment.apiKey))
        return items
    }
}
