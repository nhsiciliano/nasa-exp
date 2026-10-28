import CoreGraphics
import Foundation
import UIKit

/// What the APOD widget shows for today's entry.
nonisolated struct APODWidgetContent {
    enum Media {
        /// The picture, or the poster frame on video days.
        case image(UIImage)
        /// Entries without a still: the widget shows the title and invites to open the app.
        case openInApp
    }

    let title: String
    let displayDate: String
    /// Always shown: on video days the poster is often a third-party frame.
    let credit: String
    let isVideo: Bool
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
        // The screen-sized copy or poster; `hdURL` is the full original, which can weigh several MB.
        if let stillURL = entry.stillImageURL {
            let data = try await loadData(stillURL)
            guard let image = ImageDownsampler.downsample(data, filling: imagePixelSize) else {
                throw APODWidgetError.undecodableImage
            }
            media = .image(UIImage(cgImage: image))
        } else {
            media = .openInApp
        }

        return APODWidgetContent(
            title: entry.title,
            displayDate: entry.displayDate,
            credit: entry.shareCredit,
            isVideo: entry.isVideo,
            media: media
        )
    }
}
