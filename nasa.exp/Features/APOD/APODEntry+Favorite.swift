import Foundation

/// Favorites mapping for `APODEntry`. Kept out of `APODModels.swift` so the widget target
/// can share the APOD models without compiling the SwiftData persistence layer.
nonisolated extension APODEntry {
    var favoriteDraft: FavoriteDraft {
        let mediaKind: FavoriteMediaKind
        let mediaURL: URL?
        var hdMediaURL: URL?
        switch media {
        case let .image(url, hdURL):
            mediaKind = .image
            mediaURL = url
            hdMediaURL = hdURL
        case let .video(url):
            mediaKind = .video
            mediaURL = url
        case .unsupported:
            mediaKind = .unsupported
            mediaURL = nil
        }

        return FavoriteDraft(
            contentType: .apod,
            remoteID: id,
            title: title,
            subtitle: displayDate,
            details: explanation,
            mediaURL: mediaURL,
            originalDate: date,
            copyright: copyright,
            mediaKind: mediaKind,
            thumbnailURL: thumbnailURL,
            hdMediaURL: hdMediaURL,
            pageURL: shareURL
        )
    }

    init(favoriteItem: FavoriteItem) {
        let mediaURL = favoriteItem.mediaURL
        // Favorites saved before `mediaKindRaw` existed infer the kind from the URL.
        let mediaKind = favoriteItem.mediaKind ?? (mediaURL?.isLikelyVideo == true ? .video : .image)

        let media: Media
        switch (mediaKind, mediaURL) {
        case let (.image, url?):
            media = .image(url: url, hdURL: favoriteItem.hdMediaURL)
        case let (.video, url?):
            media = .video(url)
        default:
            media = .unsupported
        }

        self.init(
            id: favoriteItem.remoteID,
            title: favoriteItem.title,
            explanation: favoriteItem.details,
            date: favoriteItem.originalDate
                ?? APODEntry.apiFormatter.date(from: favoriteItem.remoteID)
                ?? .now,
            copyright: favoriteItem.copyright,
            media: media,
            // Favorites saved before `pageURLString` existed share the media URL instead.
            shareURL: favoriteItem.pageURL ?? mediaURL,
            thumbnailURL: favoriteItem.thumbnailURL
        )
    }
}

nonisolated private extension URL {
    var isLikelyVideo: Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi"]
        if videoExtensions.contains(pathExtension.lowercased()) {
            return true
        }

        let host = host?.lowercased() ?? ""
        return host.contains("youtube") || host.contains("youtu.be") || host.contains("vimeo")
    }
}
