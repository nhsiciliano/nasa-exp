import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text("MISSION FEED")
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.accentMuted)
                .tracking(1.4)

            Text(title)
                .font(AppTypography.display)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            Text(subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
