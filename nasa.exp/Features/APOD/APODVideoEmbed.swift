import Foundation

/// Maps APOD video links to embeddable player URLs. Only YouTube and Vimeo are embedded;
/// anything else keeps opening in the browser.
nonisolated enum APODVideoEmbed {
    static func embedURL(for url: URL) -> URL? {
        guard let host = url.host?.lowercased() else {
            return nil
        }

        if host == "youtu.be" {
            return youTubeEmbedURL(videoID: url.pathComponents.dropFirst().first)
        }

        if host == "youtube.com" || host.hasSuffix(".youtube.com")
            || host == "youtube-nocookie.com" || host.hasSuffix(".youtube-nocookie.com") {
            let components = url.pathComponents.dropFirst()
            if components.first == "embed" {
                return youTubeEmbedURL(videoID: components.dropFirst().first, keeping: url)
            }
            if components.first == "watch" || url.path == "/watch" {
                let videoID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first { $0.name == "v" }?
                    .value
                return youTubeEmbedURL(videoID: videoID)
            }
            return nil
        }

        if host == "player.vimeo.com" {
            return url.pathComponents.dropFirst().first == "video" ? url : nil
        }

        if host == "vimeo.com" || host == "www.vimeo.com" {
            guard let videoID = url.pathComponents.dropFirst().first, videoID.allSatisfy(\.isNumber) else {
                return nil
            }
            return URL(string: "https://player.vimeo.com/video/\(videoID)")
        }

        return nil
    }

    /// Builds a YouTube embed URL, preserving the query of an existing embed link and forcing inline playback.
    private static func youTubeEmbedURL(videoID: String?, keeping original: URL? = nil) -> URL? {
        guard let videoID, !videoID.isEmpty else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        // The privacy-enhanced host matches PrivacyInfo.xcprivacy declaring no tracking.
        components.host = "www.youtube-nocookie.com"
        components.path = "/embed/\(videoID)"

        var queryItems = original
            .flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        queryItems.removeAll { $0.name == "playsinline" }
        queryItems.append(URLQueryItem(name: "playsinline", value: "1"))
        components.queryItems = queryItems

        return components.url
    }
}
