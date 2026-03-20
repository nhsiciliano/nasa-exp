import Foundation

enum NASAEndpoint {
    case apod(date: String?)
    case roverPhotos(rover: String, earthDate: String, camera: String?)
    case epicNatural(date: String)

    var path: String {
        switch self {
        case .apod:
            return "/planetary/apod"
        case let .roverPhotos(rover, _, _):
            return "/mars-photos/api/v1/rovers/\(rover)/photos"
        case let .epicNatural(date):
            return "/EPIC/api/natural/date/\(date)"
        }
    }

    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []

        switch self {
        case let .apod(date):
            if let date {
                items.append(URLQueryItem(name: "date", value: date))
            }

        case let .roverPhotos(_, earthDate, camera):
            items.append(URLQueryItem(name: "earth_date", value: earthDate))
            if let camera {
                items.append(URLQueryItem(name: "camera", value: camera))
            }

        case .epicNatural:
            break
        }

        items.append(URLQueryItem(name: "api_key", value: NASAEnvironment.apiKey))
        return items
    }
}
