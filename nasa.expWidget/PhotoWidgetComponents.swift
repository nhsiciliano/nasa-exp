import SwiftUI
import WidgetKit

/// Kicker, title, detail and credit at the bottom of the Rovers and EPIC widgets.
struct PhotoWidgetCaption: View {
    let kicker: String
    let title: Text
    let detail: String
    let credit: String

    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            PhotoWidgetKicker(text: kicker)

            Spacer(minLength: 0)

            title
                .font(family == .systemSmall ? AppTypography.bodyStrong : AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            Text(verbatim: detail)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)

            Text("Crédito: \(credit)")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .accessibilityElement(children: .combine)
    }
}

struct PhotoWidgetFailure: View {
    let kicker: String
    let title: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            PhotoWidgetKicker(text: kicker)

            Spacer(minLength: 0)

            Text(title)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(3)

            Text("Lo intentamos de nuevo en un rato.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .accessibilityElement(children: .combine)
    }
}

struct PhotoWidgetKicker: View {
    let text: String

    var body: some View {
        Text(verbatim: text.uppercased())
            .font(AppTypography.micro)
            .foregroundStyle(AppColors.accent)
            .lineLimit(1)
    }
}

/// The photo filling the widget under a gradient that keeps the caption readable,
/// or the app's space gradient when there is no photo.
struct PhotoWidgetBackground: View {
    let image: UIImage?

    var body: some View {
        if let image {
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
            PhotoWidgetSpaceGradient()
        }
    }
}

struct PhotoWidgetSpaceGradient: View {
    var body: some View {
        LinearGradient(
            colors: [AppColors.backgroundGlow, AppColors.backgroundTop, AppColors.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
