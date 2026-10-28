import SwiftUI
import WidgetKit

struct EPICWidget: Widget {
    private let kind = "EPICWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Self.provider) { entry in
            EPICWidgetView(entry: entry)
        }
        .configurationDisplayName("La Tierra desde EPIC")
        .description("La última imagen completa de la Tierra que tomó EPIC.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    private static var provider: PhotoTimelineProvider<EPICWidgetContent> {
        let loader = EPICWidgetContentLoader()
        return PhotoTimelineProvider(placeholderContent: .placeholder, usesSquareImage: true) { now, pixelSize in
            await loader.load(now: now, imagePixelSize: pixelSize)
        }
    }
}

/// The globe fills the small widget; in the medium one it sits whole on the right, since
/// filling the wide shape would cut Earth into a strip.
struct EPICWidgetView: View {
    let entry: PhotoWidgetEntry<EPICWidgetContent>

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let content = entry.content {
                if family == .systemMedium {
                    HStack(spacing: AppSpacing.medium) {
                        caption(content)
                        globe(content.image)
                    }
                } else {
                    caption(content)
                }
            } else {
                PhotoWidgetFailure(kicker: "EPIC", title: "No pudimos cargar la imagen de la Tierra")
            }
        }
        .widgetURL(AppTab.epic.deepLinkURL)
        .containerBackground(for: .widget) {
            if family == .systemMedium {
                PhotoWidgetSpaceGradient()
            } else {
                PhotoWidgetBackground(image: entry.content?.image)
            }
        }
    }

    private func caption(_ content: EPICWidgetContent) -> some View {
        PhotoWidgetCaption(
            kicker: "EPIC",
            title: Text("La Tierra desde el espacio"),
            detail: content.displayDate,
            credit: content.credit
        )
    }

    @ViewBuilder
    private func globe(_ image: UIImage?) -> some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        }
    }
}

nonisolated extension EPICWidgetContent {
    static var placeholder: EPICWidgetContent {
        EPICWidgetContent(displayDate: "EPIC", credit: EPICWidgetContentLoader.credit, image: nil)
    }
}

#Preview(as: .systemMedium) {
    EPICWidget()
} timeline: {
    PhotoWidgetEntry(date: .now, content: EPICWidgetContent.placeholder)
    PhotoWidgetEntry<EPICWidgetContent>(date: .now, content: nil)
}
