import SwiftUI

struct ActionCapsule: View {
    let title: String
    let systemImage: String
    var isEmphasized: Bool = true

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(AppTypography.bodyStrong)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, AppSpacing.large)
            .padding(.vertical, AppSpacing.medium)
            .frame(maxWidth: .infinity)
            .background(background)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isEmphasized ? AppColors.borderStrong : AppColors.border, lineWidth: 1)
            }
            .accessibilityElement(children: .combine)
    }

    private var background: some ShapeStyle {
        LinearGradient(
            colors: isEmphasized
                ? [AppColors.accent.opacity(0.34), AppColors.accentMuted.opacity(0.18)]
                : [AppColors.accentSecondary.opacity(0.24), AppColors.surfaceHighlight.opacity(0.65)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}
