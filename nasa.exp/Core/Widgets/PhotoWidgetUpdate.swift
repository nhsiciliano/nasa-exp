import CoreGraphics
import Foundation
import UIKit

/// What the Rovers and EPIC widget loaders hand to their timeline: the content, or `nil`
/// when it could not be loaded, and when to ask again.
nonisolated struct PhotoWidgetUpdate<Content> {
    let content: Content?
    let nextRefresh: Date

    static func loaded(_ content: Content, now: Date) -> PhotoWidgetUpdate {
        PhotoWidgetUpdate(content: content, nextRefresh: now.addingTimeInterval(PhotoWidgetSchedule.refreshInterval))
    }

    static func failed(now: Date) -> PhotoWidgetUpdate {
        PhotoWidgetUpdate(content: nil, nextRefresh: now.addingTimeInterval(PhotoWidgetSchedule.retryInterval))
    }
}

/// Rover and EPIC photos arrive in batches through the day, with no fixed publication time
/// like APOD's, so their widgets refresh every few hours.
nonisolated enum PhotoWidgetSchedule {
    static let refreshInterval: TimeInterval = 3 * 60 * 60
    static let retryInterval: TimeInterval = 60 * 60
}

nonisolated enum PhotoWidgetError: Error {
    case noPhotos
    case undecodableImage
}

nonisolated enum PhotoWidgetImage {
    typealias DataLoader = @Sendable (URL) async throws -> Data

    /// Downloads `url` and decodes it straight to `pixelSize` (see `ImageDownsampler`).
    static func load(_ url: URL, filling pixelSize: CGSize, using loadData: DataLoader) async throws -> UIImage {
        let data = try await loadData(url)
        guard let image = ImageDownsampler.downsample(data, filling: pixelSize) else {
            throw PhotoWidgetError.undecodableImage
        }
        return UIImage(cgImage: image)
    }
}
