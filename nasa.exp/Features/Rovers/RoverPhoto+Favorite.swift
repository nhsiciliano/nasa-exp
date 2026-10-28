import Foundation

/// Favorites mapping for `RoverPhoto`. Kept out of `RoversModels.swift` so the widget target
/// can share the rover models without compiling the SwiftData persistence layer.
nonisolated extension RoverPhoto {
    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            contentType: .rover,
            remoteID: id,
            title: "\(roverName) - \(cameraName)",
            subtitle: displayDate,
            details: caption,
            mediaURL: imageURL,
            originalDate: earthDate,
            sol: sol,
            instrument: instrument.isEmpty ? nil : instrument,
            cameraFullName: cameraFullName,
            credit: credit,
            thumbnailURL: thumbnailURL
        )
    }

    init(favoriteItem: FavoriteItem) {
        let titleParts = favoriteItem.title.components(separatedBy: " - ")
        let roverTitle = titleParts.first ?? ""
        let rover: RoverName = favoriteItem.remoteID.hasPrefix("m2020-") || roverTitle == RoverName.perseverance.title
            ? .perseverance
            : .curiosity
        let cameraName = titleParts.count > 1 ? titleParts.dropFirst().joined(separator: " - ") : "Rover"

        self.init(
            id: favoriteItem.remoteID,
            rover: rover,
            sol: favoriteItem.sol ?? RoverPhoto.parseSol(from: favoriteItem.subtitle) ?? 0,
            instrument: favoriteItem.instrument ?? "",
            cameraName: cameraName,
            cameraFullName: favoriteItem.cameraFullName ?? cameraName,
            thumbnailURL: favoriteItem.thumbnailURL ?? favoriteItem.mediaURL,
            imageURL: favoriteItem.mediaURL,
            earthDate: favoriteItem.originalDate,
            caption: favoriteItem.details,
            credit: favoriteItem.credit ?? RoverPhoto.defaultCredit,
            storedDisplayDate: favoriteItem.originalDate == nil ? favoriteItem.subtitle : nil
        )
    }

    private static func parseSol(from text: String) -> Int? {
        guard let range = text.range(of: #"Sol (\d+)"#, options: .regularExpression) else {
            return nil
        }

        let digits = text[range].filter(\.isNumber)
        return Int(digits)
    }
}
