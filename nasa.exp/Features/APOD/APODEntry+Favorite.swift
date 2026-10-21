import Foundation

/// Favorites mapping for `APODEntry`. Kept out of `APODModels.swift` so the widget target
/// can share the APOD models without compiling the SwiftData persistence layer.
nonisolated extension APODEntry {
    var favoriteDraft: FavoriteDraft {
        let mediaKind: FavoriteMediaKind
        switch media {
        case .image:
            mediaKind = .image
        case .video:
            mediaKind = .video
        case .unsupported:
            mediaKind = .unsupported
        }

        return FavoriteDraft(
            contentType: .apod,
            remoteID: id,
            title: title,
            subtitle: displayDate,
            details: explanation,
            mediaURL: shareURL,
            originalDate: date,
            copyright: copyright,
            mediaKind: mediaKind
        )
    }

    init(favoriteItem: FavoriteItem) {
        let mediaURL = favoriteItem.mediaURL
        // Favorites saved before `mediaKindRaw` existed infer the kind from the URL.
        let mediaKind = favoriteItem.mediaKind ?? (mediaURL?.isLikelyVideo == true ? .video : .image)

        let media: Media
        switch (mediaKind, mediaURL) {
        case let (.image, url?):
            media = .image(url)
        case let (.video, url?):
            media = .video(url)
        default:
            media = .unsupported
        }

        self.id = favoriteItem.remoteID
        self.title = favoriteItem.title
        self.explanation = favoriteItem.details
        self.date = favoriteItem.originalDate
            ?? APODEntry.apiFormatter.date(from: favoriteItem.remoteID)
            ?? .now
        self.copyright = favoriteItem.copyright
        self.media = media
        self.shareURL = mediaURL
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
