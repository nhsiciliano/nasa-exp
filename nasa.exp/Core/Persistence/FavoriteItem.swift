import Foundation
import SwiftData

nonisolated enum FavoriteContentType: String, Codable {
    case apod
    case rover
    case epic
}

nonisolated enum FavoriteMediaKind: String, Codable {
    case image
    case video
    case unsupported
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

    // Original metadata used to rebuild the native detail screens:
    // - APOD: originalDate, copyright, mediaKindRaw
    // - Rover: originalDate (earth date), sol, instrument, cameraFullName, credit, thumbnailURLString
    // - EPIC: originalDate, latitude, longitude
    // Every field is optional so SwiftData migrates existing stores automatically (lightweight
    // migration). They are nil on favorites saved before they existed, so readers need a fallback.
    var originalDate: Date?
    var copyright: String?
    var mediaKindRaw: String?
    var sol: Int?
    var instrument: String?
    var cameraFullName: String?
    var credit: String?
    var latitude: Double?
    var longitude: Double?
    var thumbnailURLString: String?

    init(
        key: String,
        contentTypeRaw: String,
        remoteID: String,
        title: String,
        subtitle: String,
        details: String,
        mediaURLString: String,
        createdAt: Date = .now,
        originalDate: Date? = nil,
        copyright: String? = nil,
        mediaKindRaw: String? = nil,
        sol: Int? = nil,
        instrument: String? = nil,
        cameraFullName: String? = nil,
        credit: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        thumbnailURLString: String? = nil
    ) {
        self.key = key
        self.contentTypeRaw = contentTypeRaw
        self.remoteID = remoteID
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.mediaURLString = mediaURLString
        self.createdAt = createdAt
        self.originalDate = originalDate
        self.copyright = copyright
        self.mediaKindRaw = mediaKindRaw
        self.sol = sol
        self.instrument = instrument
        self.cameraFullName = cameraFullName
        self.credit = credit
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailURLString = thumbnailURLString
    }

    var contentType: FavoriteContentType {
        FavoriteContentType(rawValue: contentTypeRaw) ?? .apod
    }

    var mediaURL: URL? {
        URL(string: mediaURLString)
    }

    var mediaKind: FavoriteMediaKind? {
        mediaKindRaw.flatMap(FavoriteMediaKind.init(rawValue:))
    }

    var thumbnailURL: URL? {
        thumbnailURLString.flatMap(URL.init(string:))
    }
}

nonisolated struct FavoriteDraft {
    let contentType: FavoriteContentType
    let remoteID: String
    let title: String
    let subtitle: String
    let details: String
    let mediaURL: URL?
    let originalDate: Date?
    let copyright: String?
    let mediaKind: FavoriteMediaKind?
    let sol: Int?
    let instrument: String?
    let cameraFullName: String?
    let credit: String?
    let latitude: Double?
    let longitude: Double?
    let thumbnailURL: URL?

    init(
        contentType: FavoriteContentType,
        remoteID: String,
        title: String,
        subtitle: String,
        details: String,
        mediaURL: URL?,
        originalDate: Date? = nil,
        copyright: String? = nil,
        mediaKind: FavoriteMediaKind? = nil,
        sol: Int? = nil,
        instrument: String? = nil,
        cameraFullName: String? = nil,
        credit: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        thumbnailURL: URL? = nil
    ) {
        self.contentType = contentType
        self.remoteID = remoteID
        self.title = title
        self.subtitle = subtitle
        self.details = details
        self.mediaURL = mediaURL
        self.originalDate = originalDate
        self.copyright = copyright
        self.mediaKind = mediaKind
        self.sol = sol
        self.instrument = instrument
        self.cameraFullName = cameraFullName
        self.credit = credit
        self.latitude = latitude
        self.longitude = longitude
        self.thumbnailURL = thumbnailURL
    }

    var key: String {
        "\(contentType.rawValue)-\(remoteID)"
    }
}
