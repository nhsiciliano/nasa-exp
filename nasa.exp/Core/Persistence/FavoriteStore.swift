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

    /// Saves the draft as a favorite, or updates the stored one with its fields. `createdAt` is kept,
    /// and fields the draft leaves nil keep their stored value, so an update never loses metadata.
    static func upsert(_ draft: FavoriteDraft, in context: ModelContext) {
        if let favorite = favorite(for: draft, in: context) {
            guard favorite.merge(draft) else {
                return
            }
        } else {
            let favorite = FavoriteItem(
                key: draft.key,
                contentTypeRaw: draft.contentType.rawValue,
                remoteID: draft.remoteID,
                title: draft.title,
                subtitle: draft.subtitle,
                details: draft.details,
                mediaURLString: ""
            )
            _ = favorite.merge(draft)
            context.insert(favorite)
        }

        try? context.save()
    }

    /// Updates a stored favorite with the draft of the live entry it shows, so favorites saved
    /// by older versions gain the metadata they lack. Returns whether the draft is a favorite.
    static func refreshIfFavorite(_ draft: FavoriteDraft, in context: ModelContext) -> Bool {
        guard let favorite = favorite(for: draft, in: context) else {
            return false
        }

        if favorite.merge(draft) {
            try? context.save()
        }
        return true
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

    private static func favorite(for draft: FavoriteDraft, in context: ModelContext) -> FavoriteItem? {
        let key = draft.key
        var descriptor = FetchDescriptor<FavoriteItem>(
            predicate: #Predicate { item in
                item.key == key
            }
        )
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }
}

private extension FavoriteItem {
    /// Copies the draft's fields, keeping stored values where the draft has none.
    /// Returns whether anything changed, so unchanged favorites are not saved again.
    func merge(_ draft: FavoriteDraft) -> Bool {
        var hasChanges = false

        func update<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<FavoriteItem, Value>, to value: Value) {
            guard self[keyPath: keyPath] != value else {
                return
            }
            self[keyPath: keyPath] = value
            hasChanges = true
        }

        func fill<Value: Equatable>(_ keyPath: ReferenceWritableKeyPath<FavoriteItem, Value?>, with value: Value?) {
            if let value {
                update(keyPath, to: value)
            }
        }

        update(\.title, to: draft.title)
        update(\.subtitle, to: draft.subtitle)
        update(\.details, to: draft.details)
        if let mediaURLString = Self.storedString(for: draft.mediaURL) {
            update(\.mediaURLString, to: mediaURLString)
        }
        fill(\.originalDate, with: draft.originalDate)
        fill(\.copyright, with: draft.copyright)
        fill(\.mediaKindRaw, with: draft.mediaKind?.rawValue)
        fill(\.sol, with: draft.sol)
        fill(\.instrument, with: draft.instrument)
        fill(\.cameraFullName, with: draft.cameraFullName)
        fill(\.credit, with: draft.credit)
        fill(\.latitude, with: draft.latitude)
        fill(\.longitude, with: draft.longitude)
        fill(\.thumbnailURLString, with: Self.storedString(for: draft.thumbnailURL))
        fill(\.hdMediaURLString, with: Self.storedString(for: draft.hdMediaURL))
        fill(\.pageURLString, with: Self.storedString(for: draft.pageURL))

        return hasChanges
    }

    /// The URL as persisted, without an `api_key` query item: EPIC images were once served by
    /// `api.nasa.gov` with the key in the URL, and the key must not live in the favorites store.
    static func storedString(for url: URL?) -> String? {
        guard let url else {
            return nil
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              queryItems.contains(where: { $0.name == "api_key" }) else {
            return url.absoluteString
        }

        let remainingItems = queryItems.filter { $0.name != "api_key" }
        components.queryItems = remainingItems.isEmpty ? nil : remainingItems
        return components.url?.absoluteString ?? url.absoluteString
    }
}
