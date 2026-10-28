import SwiftUI
import WidgetKit

nonisolated struct APODWidgetEntry: TimelineEntry {
    let date: Date
    /// `nil` when today's APOD could not be loaded.
    let content: APODWidgetContent?
}

/// One entry per day: today's APOD, refreshed when the next one is expected.
nonisolated struct APODTimelineProvider: TimelineProvider {
    private let loader = APODWidgetContentLoader()

    func placeholder(in context: Context) -> APODWidgetEntry {
        APODWidgetEntry(date: .now, content: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (APODWidgetEntry) -> Void) {
        guard !context.isPreview else {
            completion(placeholder(in: context))
            return
        }

        let pixelSize = Self.imagePixelSize(for: context)
        Task {
            let update = await loader.load(now: .now, imagePixelSize: pixelSize)
            completion(APODWidgetEntry(date: .now, content: update.content))
        }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<APODWidgetEntry>) -> Void) {
        let pixelSize = Self.imagePixelSize(for: context)
        Task {
            let now = Date.now
            let update = await loader.load(now: now, imagePixelSize: pixelSize)
            let entry = APODWidgetEntry(date: now, content: update.content)
            completion(Timeline(entries: [entry], policy: .after(update.nextRefresh)))
        }
    }

    private static func imagePixelSize(for context: Context) -> CGSize {
        // 2x when WidgetKit does not report the scale: sharp enough and within its image size limit on every iPhone.
        let scale = context.environmentVariants.displayScale?.max() ?? 2
        return CGSize(width: context.displaySize.width * scale, height: context.displaySize.height * scale)
    }
}

nonisolated extension APODWidgetContent {
    static var placeholder: APODWidgetContent {
        APODWidgetContent(
            title: String(localized: "Foto astronómica del día"),
            displayDate: "APOD",
            credit: "NASA",
            isVideo: false,
            media: .openInApp
        )
    }
}
