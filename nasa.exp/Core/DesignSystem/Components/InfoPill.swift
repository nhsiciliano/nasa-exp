import SwiftUI

struct InfoPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTypography.micro)
            .foregroundStyle(AppColors.accentMuted)
            .tracking(0.8)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColors.surfaceHighlight.opacity(0.72))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(AppColors.border, lineWidth: 1)
            }
    }
}
