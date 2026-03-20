import SwiftUI

struct HeroCard: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.18))
                        .frame(width: 46, height: 46)

                    Image(systemName: symbolName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.accent)
                }

                Spacer(minLength: 0)

                Text("LIVE DATA")
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.accentMuted)
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.small)
                    .background(AppColors.accent.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(title)
                .font(AppTypography.largeTitle)
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
                .lineSpacing(3)
                .lineLimit(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [AppColors.surfaceHighlight.opacity(0.96), AppColors.surfaceBase.opacity(0.96)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppColors.borderStrong, lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(AppColors.accent.opacity(0.08))
                .frame(width: 140, height: 140)
                .offset(x: 36, y: 34)
        }
        .accessibilityElement(children: .combine)
    }
}
