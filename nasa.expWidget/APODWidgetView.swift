import SwiftUI
import WidgetKit

struct APODWidgetView: View {
    let entry: APODWidgetEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let content = entry.content {
                contentView(content)
            } else {
                failureView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .widgetURL(AppTab.apod.deepLinkURL)
        .containerBackground(for: .widget) {
            background
        }
    }

    private func contentView(_ content: APODWidgetContent) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            kicker

            Spacer(minLength: 0)

            if content.isVideo {
                Image(systemName: "play.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.accent)
                    .accessibilityHidden(true)
            }

            Text(content.title)
                .font(family == .systemSmall ? AppTypography.bodyStrong : AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            Text(content.displayDate)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            Text("Crédito: \(content.credit)")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }

    private var failureView: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            kicker

            Spacer(minLength: 0)

            Text("No pudimos cargar la foto del día")
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(3)

            Text("Lo intentamos de nuevo en un rato.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }

    private var kicker: some View {
        Text(verbatim: "APOD")
            .font(AppTypography.micro)
            .foregroundStyle(AppColors.accent)
    }

    @ViewBuilder
    private var background: some View {
        if case let .image(image)? = entry.content?.media {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .overlay {
                    LinearGradient(
                        colors: [.clear, AppColors.backgroundBottom.opacity(0.9)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                }
                .accessibilityHidden(true)
        } else {
            LinearGradient(
                colors: [AppColors.backgroundGlow, AppColors.backgroundTop, AppColors.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
