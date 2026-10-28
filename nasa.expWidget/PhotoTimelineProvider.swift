import SwiftUI
import WidgetKit

nonisolated struct PhotoWidgetEntry<Content>: TimelineEntry {
    let date: Date
    /// `nil` when the photo could not be loaded.
    let content: Content?
}

/// Timeline of the Rovers and EPIC widgets: one entry with the newest photo, refreshed every
/// few hours (`PhotoWidgetSchedule`). Each widget passes its loader and how big its image is.
nonisolated struct PhotoTimelineProvider<Content>: TimelineProvider {
    typealias Load = @Sendable (_ now: Date, _ imagePixelSize: CGSize) async -> PhotoWidgetUpdate<Content>

    let placeholderContent: Content
    /// Whether the image is drawn as a square (EPIC's globe) instead of filling the widget.
    let usesSquareImage: Bool
    let load: Load

    func placeholder(in context: Context) -> PhotoWidgetEntry<Content> {
        PhotoWidgetEntry(date: .now, content: placeholderContent)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (PhotoWidgetEntry<Content>) -> Void) {
        guard !context.isPreview else {
            completion(placeholder(in: context))
            return
        }

        let pixelSize = imagePixelSize(for: context)
        Task {
            let update = await load(.now, pixelSize)
            completion(PhotoWidgetEntry(date: .now, content: update.content))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<PhotoWidgetEntry<Content>>) -> Void) {
        let pixelSize = imagePixelSize(for: context)
        Task {
            let now = Date.now
            let update = await load(now, pixelSize)
            let entry = PhotoWidgetEntry(date: now, content: update.content)
            completion(Timeline(entries: [entry], policy: .after(update.nextRefresh)))
        }
    }

    private func imagePixelSize(for context: Context) -> CGSize {
        // 2x when WidgetKit does not report the scale, as in the APOD widget.
        let scale = context.environmentVariants.displayScale?.max() ?? 2
        let size = context.displaySize
        guard usesSquareImage else {
            return CGSize(width: size.width * scale, height: size.height * scale)
        }

        let side = min(size.width, size.height) * scale
        return CGSize(width: side, height: side)
    }
}
