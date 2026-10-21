import Foundation

/// Where APOD lives since `api.nasa.gov/planetary/apod` stopped serving real entries (2026): the
/// science.nasa.gov site. Neither source needs an API key.
nonisolated enum APODSource {
    /// "APOD Basic" RSS feed with the latest 30 entries, newest first.
    static let feedURL = URL(string: "https://science.nasa.gov/feed/apod-basic/")!

    /// Number of days the RSS feed covers, counting today.
    static let feedWindowDays = 30

    /// WordPress query for the APOD post of the US Eastern day `id` (`yyyy-MM-dd`).
    static func archivePostURL(for id: String) -> URL? {
        guard let previousID = APODDay.id(id, offsetBy: -1) else {
            return nil
        }

        var components = URLComponents(string: "https://science.nasa.gov/wp-json/wp/v2/image-article")
        components?.queryItems = [
            URLQueryItem(name: "categories", value: "22766"),
            URLQueryItem(name: "per_page", value: "1"),
            // Dates are in site time (US Eastern). `after` is exclusive and archive posts are stamped
            // at exactly 00:00, so the window starts at the last second of the previous day.
            URLQueryItem(name: "after", value: "\(previousID)T23:59:59"),
            URLQueryItem(name: "before", value: "\(id)T23:59:59"),
            URLQueryItem(name: "_fields", value: "date,link,title,content,featured_image_url")
        ]
        return components?.url
    }

    /// WordPress query for the newest APOD post, used when the RSS feed is unavailable.
    static var latestArchivePostURL: URL? {
        var components = URLComponents(string: "https://science.nasa.gov/wp-json/wp/v2/image-article")
        components?.queryItems = [
            URLQueryItem(name: "categories", value: "22766"),
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "orderby", value: "date"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "_fields", value: "date,link,title,content,featured_image_url")
        ]
        return components?.url
    }
}

/// Sizing for images on `assets.science.nasa.gov`, which resizes on the fly from `w`/`fit` query
/// items. Archive images under `content/dam` ignore them and always serve the (small) original.
nonisolated enum APODImageURL {
    private static let host = "assets.science.nasa.gov"

    /// The asset scaled down to `width` pixels; never upscaled.
    static func resized(_ url: URL, width: Int) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == host else {
            return url
        }

        components.queryItems = [
            URLQueryItem(name: "w", value: "\(width)"),
            URLQueryItem(name: "fit", value: "clip")
        ]
        return components.url ?? url
    }

    /// The full-size original: the same asset without sizing query items.
    static func original(_ url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.host == host else {
            return url
        }

        components.query = nil
        return components.url ?? url
    }

    /// Whether `url` is an APOD picture, as opposed to the generic placeholder WordPress uses
    /// when a post has no featured image.
    static func isAPODImage(_ url: URL) -> Bool {
        url.host == host && url.path.contains("/cds/apod/")
    }
}
