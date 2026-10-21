import Foundation

/// One APOD as published on science.nasa.gov, whichever source it came from: the RSS feed for
/// recent days or the WordPress API for the archive. Text fields are plain text, without HTML.
nonisolated struct APODRecord: Sendable {
    /// `yyyy-MM-dd` of the US Eastern day the entry was published for (see `APODDay`).
    let id: String
    let title: String
    let explanation: String
    let credit: String?
    /// Article page on science.nasa.gov.
    let pageURL: URL?
    /// Full-size image, or the poster frame when the entry is a video.
    let imageURL: URL?
    /// Embedded player (YouTube, Vimeo) when the entry is a video.
    let videoURL: URL?
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
    /// Credit line ("Credit & Copyright"), as plain text.
    let copyright: String?
    let media: Media
    /// Article page on science.nasa.gov.
    let shareURL: URL?
    /// Small still for lists: a reduced copy of the image, or the poster of a video.
    let thumbnailURL: URL?

    init(
        id: String,
        title: String,
        explanation: String,
        date: Date,
        copyright: String?,
        media: Media,
        shareURL: URL?,
        thumbnailURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.date = date
        self.copyright = copyright
        self.media = media
        self.shareURL = shareURL
        self.thumbnailURL = thumbnailURL
    }

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
    /// Width of the image shown on screen; the original is kept as `hdURL` for full screen.
    static let screenImageWidth = 1280
    static let thumbnailWidth = 480

    init(record: APODRecord) {
        let media: Media
        if let videoURL = record.videoURL {
            media = .video(videoURL)
        } else if let imageURL = record.imageURL {
            media = .image(
                url: APODImageURL.resized(imageURL, width: APODEntry.screenImageWidth),
                hdURL: imageURL
            )
        } else {
            media = .unsupported
        }

        self.init(
            id: record.id,
            title: record.title,
            explanation: record.explanation,
            date: APODEntry.apiFormatter.date(from: record.id) ?? .now,
            copyright: record.credit,
            media: media,
            shareURL: record.pageURL,
            thumbnailURL: record.imageURL.map { APODImageURL.resized($0, width: APODEntry.thumbnailWidth) }
        )
    }

    /// Parses `yyyy-MM-dd` APOD ids into local-midnight dates, the calendar days the app works with.
    static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
