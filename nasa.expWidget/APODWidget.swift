import SwiftUI
import WidgetKit

@main
struct APODWidget: Widget {
    private let kind = "APODWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: APODTimelineProvider()) { entry in
            APODWidgetView(entry: entry)
        }
        .configurationDisplayName("Foto astronómica del día")
        .description("La imagen de APOD de hoy, actualizada cada día.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    APODWidget()
} timeline: {
    APODWidgetEntry(date: .now, content: .placeholder)
    APODWidgetEntry(date: .now, content: nil)
}
