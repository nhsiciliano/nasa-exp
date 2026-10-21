import Foundation
import SwiftData

enum FavoriteStore {
    static func contains(_ draft: FavoriteDraft, in context: ModelContext) -> Bool {
        let key = draft.key
        let descriptor = FetchDescriptor<FavoriteItem>(
            predicate: #Predicate { item in
                item.key == key
            }
        )

        do {
            return try context.fetchCount(descriptor) > 0
        } catch {
            return false
        }
    }

    static func add(_ draft: FavoriteDraft, in context: ModelContext) {
        guard !contains(draft, in: context) else {
            return
        }

        let favorite = FavoriteItem(
            key: draft.key,
            contentTypeRaw: draft.contentType.rawValue,
            remoteID: draft.remoteID,
            title: draft.title,
            subtitle: draft.subtitle,
            details: draft.details,
            mediaURLString: draft.mediaURL?.absoluteString ?? "",
            originalDate: draft.originalDate,
            copyright: draft.copyright,
            mediaKindRaw: draft.mediaKind?.rawValue,
            sol: draft.sol,
            instrument: draft.instrument,
            cameraFullName: draft.cameraFullName,
            credit: draft.credit,
            latitude: draft.latitude,
            longitude: draft.longitude,
            thumbnailURLString: draft.thumbnailURL?.absoluteString
        )

        context.insert(favorite)
        try? context.save()
    }

    static func remove(_ draft: FavoriteDraft, in context: ModelContext) {
        let key = draft.key
        let descriptor = FetchDescriptor<FavoriteItem>(
            predicate: #Predicate { item in
                item.key == key
            }
        )

        do {
            let matches = try context.fetch(descriptor)
            for item in matches {
                context.delete(item)
            }
            try context.save()
        } catch {
            return
        }
    }
}
