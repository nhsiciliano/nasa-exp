import Foundation

struct APODResponseDTO: Decodable {
    let title: String
    let explanation: String
    let date: String
    let mediaType: String
    let url: String
    let hdurl: String?
    let copyright: String?
}

struct APODEntry: Identifiable {
    enum Media {
        case image(URL)
        case video(URL)
        case unsupported
    }

    let id: String
    let title: String
    let explanation: String
    let date: Date
    let copyright: String?
    let media: Media
    let shareURL: URL?

    var displayDate: String {
        APODEntry.displayFormatter.string(from: date)
    }

    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            contentType: .apod,
            remoteID: id,
            title: title,
            subtitle: displayDate,
            details: explanation,
            mediaURL: shareURL
        )
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .long
        return formatter
    }()
}

extension APODEntry {
    init(dto: APODResponseDTO) {
        let parsedDate = APODEntry.apiFormatter.date(from: dto.date) ?? .now
        let mediaURL = URL(string: dto.url)
        let hdURL = URL(string: dto.hdurl ?? "")

        let media: Media
        if dto.mediaType == "image", let imageURL = mediaURL {
            media = .image(hdURL ?? imageURL)
        } else if dto.mediaType == "video", let videoURL = mediaURL {
            media = .video(videoURL)
        } else {
            media = .unsupported
        }

        self.id = dto.date
        self.title = dto.title
        self.explanation = dto.explanation
        self.date = parsedDate
        self.copyright = dto.copyright
        self.media = media
        self.shareURL = mediaURL
    }

    init(favoriteItem: FavoriteItem) {
        let remoteDate = APODEntry.apiFormatter.date(from: favoriteItem.remoteID) ?? .now
        let mediaURL = favoriteItem.mediaURL

        let media: Media
        if let mediaURL {
            if mediaURL.isLikelyVideo {
                media = .video(mediaURL)
            } else {
                media = .image(mediaURL)
            }
        } else {
            media = .unsupported
        }

        self.id = favoriteItem.remoteID
        self.title = favoriteItem.title
        self.explanation = favoriteItem.details
        self.date = remoteDate
        self.copyright = nil
        self.media = media
        self.shareURL = mediaURL
    }

    private static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension URL {
    var isLikelyVideo: Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "avi"]
        if videoExtensions.contains(pathExtension.lowercased()) {
            return true
        }

        let host = host?.lowercased() ?? ""
        return host.contains("youtube") || host.contains("youtu.be") || host.contains("vimeo")
    }
}
