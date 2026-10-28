import SwiftUI
import WidgetKit

struct RoversWidget: Widget {
    private let kind = "RoversWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Self.provider) { entry in
            RoversWidgetView(entry: entry)
        }
        .configurationDisplayName("Última foto de Marte")
        .description("La foto más reciente de Perseverance o Curiosity, actualizada cada pocas horas.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }

    private static var provider: PhotoTimelineProvider<RoversWidgetContent> {
        let loader = RoversWidgetContentLoader()
        return PhotoTimelineProvider(placeholderContent: .placeholder, usesSquareImage: false) { now, pixelSize in
            await loader.load(now: now, imagePixelSize: pixelSize)
        }
    }
}

struct RoversWidgetView: View {
    let entry: PhotoWidgetEntry<RoversWidgetContent>

    var body: some View {
        Group {
            if let content = entry.content {
                PhotoWidgetCaption(
                    kicker: content.roverName,
                    title: Text(verbatim: content.cameraName),
                    detail: content.detail,
                    credit: content.credit
                )
            } else {
                PhotoWidgetFailure(kicker: "Rovers", title: "No pudimos cargar la foto de Marte")
            }
        }
        .widgetURL(AppTab.rovers.deepLinkURL)
        .containerBackground(for: .widget) {
            PhotoWidgetBackground(image: entry.content?.image)
        }
    }
}

nonisolated extension RoversWidgetContent {
    static var placeholder: RoversWidgetContent {
        RoversWidgetContent(
            roverName: RoverName.perseverance.title,
            cameraName: RoverCamera.mastcamZ.title,
            detail: "Sol",
            credit: RoverPhoto.defaultCredit,
            image: nil
        )
    }
}

#Preview(as: .systemMedium) {
    RoversWidget()
} timeline: {
    PhotoWidgetEntry(date: .now, content: RoversWidgetContent.placeholder)
    PhotoWidgetEntry<RoversWidgetContent>(date: .now, content: nil)
}
