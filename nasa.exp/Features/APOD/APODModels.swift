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

    var isVideo: Bool {
        if case .video = media {
            return true
        }
        return false
    }

    /// The still that stands for the entry when it is shared, saved or shown in the widget: the
    /// screen-sized image, or the poster frame of a video. For videos the thumbnail is the reduced
    /// poster, so it is resized back to screen width (a no-op for posters outside the APOD CDN).
    var stillImageURL: URL? {
        switch media {
        case let .image(url, _):
            return url
        case .video:
            return thumbnailURL.map { APODImageURL.resized($0, width: APODEntry.screenImageWidth) }
        case .unsupported:
            return nil
        }
    }

    /// The credit line on one line, or "NASA" when the entry has none. Shown wherever the
    /// picture travels without the app around it: shares, saved copies and the widget.
    var shareCredit: String {
        let credit = (copyright ?? "")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        return credit.isEmpty ? "NASA" : credit
    }

    var displayDate: String {
        APODEntry.displayFormatter.string(from: date)
    }

    /// `displayDate` for an explicit locale and time zone instead of the device's.
    func displayDate(locale: Locale, timeZone: TimeZone = .current) -> String {
        APODEntry.makeDisplayFormatter(locale: locale, timeZone: timeZone).string(from: date)
    }

    private static let displayFormatter = makeDisplayFormatter(locale: .current, timeZone: .current)

    private static func makeDisplayFormatter(locale: Locale, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .long
        return formatter
    }
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
