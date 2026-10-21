import Foundation
import SwiftData

nonisolated enum FavoriteContentType: String, Codable {
    case apod
    case rover
    case epic
}

@Model
final class FavoriteItem {
    @Attribute(.unique) var key: String
    var contentTypeRaw: String
    var remoteID: String
    var title: String
    var subtitle: String
    var details: String
    var mediaURLString: String
    var createdAt: Date

    init(
        key: String,
        contentTypeRaw: String,
        remoteID: String,
        title: String,
        subtitle: String,
        details: String,
        mediaURLString: String,
        createdAt: Date = .now
    ) {
        self.key = key
        self.contentTypeRaw = contentTypeRaw
        self.remoteID = remoteID
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.mediaURLString = mediaURLString
        self.createdAt = createdAt
    }

    var contentType: FavoriteContentType {
        FavoriteContentType(rawValue: contentTypeRaw) ?? .apod
    }

    var mediaURL: URL? {
        URL(string: mediaURLString)
    }
}

nonisolated struct FavoriteDraft {
    let contentType: FavoriteContentType
    let remoteID: String
    let title: String
    let subtitle: String
    let details: String
    let mediaURL: URL?

    var key: String {
        "\(contentType.rawValue)-\(remoteID)"
    }
}
