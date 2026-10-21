import CoreGraphics
import Foundation
import UIKit

/// What the APOD widget shows for today's entry.
nonisolated struct APODWidgetContent {
    enum Media {
        case image(UIImage)
        /// Videos and interactive entries: the widget shows the title and invites to open the app.
        case openInApp
    }

    let title: String
    let displayDate: String
    let media: Media
}

nonisolated struct APODWidgetUpdate {
    /// `nil` when today's APOD could not be loaded.
    let content: APODWidgetContent?
    let nextRefresh: Date
}

nonisolated enum APODWidgetError: Error {
    case undecodableImage
}

/// Loads today's APOD for the widget, with the image already downsampled to the widget size.
/// Shared with the widget extension; it lives in the app target so the unit tests can reach it.
nonisolated struct APODWidgetContentLoader {
    typealias DataLoader = @Sendable (URL) async throws -> Data

    private let repository: APODRepositoryProtocol
    private let loadData: DataLoader

    init(
        repository: APODRepositoryProtocol = APODRepository(),
        loadData: @escaping DataLoader = { url in try await NASAClient().fetchData(url: url) }
    ) {
        self.repository = repository
        self.loadData = loadData
    }

    func load(now: Date, imagePixelSize: CGSize) async -> APODWidgetUpdate {
        do {
            let entry = try await repository.fetchToday()
            let content = try await content(for: entry, imagePixelSize: imagePixelSize)
            return APODWidgetUpdate(
                content: content,
                nextRefresh: APODPublicationSchedule.nextRefresh(after: now, showing: entry.id)
            )
        } catch {
            // The widget shows its failure state and retries on the next refresh.
            return APODWidgetUpdate(
                content: nil,
                nextRefresh: APODPublicationSchedule.nextRefresh(after: now, showing: nil)
            )
        }
    }

    private func content(for entry: APODEntry, imagePixelSize: CGSize) async throws -> APODWidgetContent {
        let media: APODWidgetContent.Media
        switch entry.media {
        case let .image(imageURL, _):
            // The screen-sized copy; `hdURL` is the full original, which can weigh several MB.
            let data = try await loadData(imageURL)
            guard let image = ImageDownsampler.downsample(data, filling: imagePixelSize) else {
                throw APODWidgetError.undecodableImage
            }
            media = .image(UIImage(cgImage: image))
        case .video, .unsupported:
            media = .openInApp
        }

        return APODWidgetContent(title: entry.title, displayDate: entry.displayDate, media: media)
    }
}
