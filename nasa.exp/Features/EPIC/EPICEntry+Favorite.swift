import Foundation

/// Favorites mapping for `EPICEntry`. Kept out of `EPICModels.swift` so the widget target
/// can share the EPIC models without compiling the SwiftData persistence layer.
nonisolated extension EPICEntry {
    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            contentType: .epic,
            remoteID: id,
            title: title,
            subtitle: displayDate,
            details: caption,
            mediaURL: imageURL,
            originalDate: date,
            latitude: latitude,
            longitude: longitude,
            thumbnailURL: thumbnailURL
        )
    }

    init(favoriteItem: FavoriteItem) {
        self.id = favoriteItem.remoteID
        self.title = favoriteItem.title
        self.caption = favoriteItem.details
        self.date = favoriteItem.originalDate ?? .now
        self.latitude = favoriteItem.latitude ?? 0
        self.longitude = favoriteItem.longitude ?? 0
        self.imageURL = favoriteItem.mediaURL
        self.thumbnailURL = favoriteItem.thumbnailURL
    }
}
