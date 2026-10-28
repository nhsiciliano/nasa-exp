import CoreGraphics
import Foundation
import UIKit

/// What the EPIC widget shows: the latest full-disk image of Earth.
nonisolated struct EPICWidgetContent {
    let displayDate: String
    let credit: String
    /// `nil` only in the gallery placeholder.
    let image: UIImage?
}

/// Loads the newest EPIC image from `epic.gsfc.nasa.gov`, which serves the same JSON as
/// `api.nasa.gov/EPIC` without a key, so the widget never carries `NASA_API_KEY`.
/// Shared with the widget extension; it lives in the app target so the unit tests can reach it.
nonisolated struct EPICWidgetContentLoader {
    typealias DataLoader = @Sendable (URL) async throws -> Data

    /// Entries of the most recent day with imagery.
    static let latestURL = URL(string: "https://epic.gsfc.nasa.gov/api/natural")!
    static let credit = "NASA EPIC Team"

    private let loadData: DataLoader

    init(loadData: @escaping DataLoader = { url in try await NASAClient().fetchData(url: url) }) {
        self.loadData = loadData
    }

    func load(now: Date, imagePixelSize: CGSize) async -> PhotoWidgetUpdate<EPICWidgetContent> {
        do {
            let data = try await loadData(Self.latestURL)
            let entries = try NASAClient.decode([EPICEntryDTO].self, from: data).map(EPICEntry.init(dto:))
            // The 1080 px JPEG, not the multi-megabyte PNG the detail view uses.
            guard let latest = entries.max(by: { $0.date < $1.date }),
                  let imageURL = latest.jpegURL ?? latest.imageURL else {
                throw PhotoWidgetError.noPhotos
            }

            let image = try await PhotoWidgetImage.load(imageURL, filling: imagePixelSize, using: loadData)
            return .loaded(EPICWidgetContent(displayDate: latest.displayDate, credit: Self.credit, image: image), now: now)
        } catch {
            // The widget shows its failure state and retries sooner than a regular refresh.
            return .failed(now: now)
        }
    }
}
