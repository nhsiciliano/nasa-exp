import Foundation

/// Builds requests against the public raw-image feeds on `mars.nasa.gov`.
/// These feeds need no API key and replace the discontinued `api.nasa.gov/mars-photos` service.
nonisolated struct MarsRawImagesRequest {
    static let defaultPageSize = 40

    let rover: RoverName
    /// `nil` returns the newest images regardless of sol.
    let sol: Int?
    let camera: RoverCamera
    let page: Int
    var pageSize: Int = MarsRawImagesRequest.defaultPageSize

    var url: URL? {
        var components: URLComponents?
        var items: [URLQueryItem] = []

        switch rover {
        case .curiosity:
            components = URLComponents(string: "https://mars.nasa.gov/api/v1/raw_image_items/")
            items = [
                URLQueryItem(name: "order", value: "sol desc"),
                URLQueryItem(name: "per_page", value: "\(pageSize)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "condition_1", value: "msl:mission"),
                URLQueryItem(name: "extended", value: "thumbnail::sample_type::noteq")
            ]

        case .perseverance:
            components = URLComponents(string: "https://mars.nasa.gov/rss/api/")
            items = [
                URLQueryItem(name: "feed", value: "raw_images"),
                URLQueryItem(name: "category", value: "mars2020"),
                URLQueryItem(name: "feedtype", value: "json"),
                URLQueryItem(name: "order", value: "sol desc"),
                URLQueryItem(name: "num", value: "\(pageSize)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "extended", value: "sample_type::full,")
            ]
        }

        if let sol {
            items.append(URLQueryItem(name: "condition_2", value: "\(sol):sol:gte"))
            items.append(URLQueryItem(name: "condition_3", value: "\(sol):sol:lte"))
        }

        if let search = camera.searchValue(for: rover) {
            items.append(URLQueryItem(name: "search", value: search))
        }

        components?.queryItems = items
        return components?.url
    }
}
