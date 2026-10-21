import Foundation

nonisolated struct APODResponseDTO: Decodable {
    let title: String
    let explanation: String
    let date: String
    let mediaType: String
    let url: String
    let hdurl: String?
    let copyright: String?
}

nonisolated struct APODEntry: Identifiable {
    enum Media {
        case image(url: URL, hdURL: URL?)
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

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        return formatter
    }()
}

nonisolated extension APODEntry {
    init(dto: APODResponseDTO) {
        let parsedDate = APODEntry.apiFormatter.date(from: dto.date) ?? .now
        let mediaURL = URL(string: dto.url)
        let hdURL = URL(string: dto.hdurl ?? "")

        let media: Media
        if dto.mediaType == "image", let imageURL = mediaURL {
            media = .image(url: imageURL, hdURL: hdURL)
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

    /// Parses the `yyyy-MM-dd` dates used by the APOD API and as APOD ids.
    static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
