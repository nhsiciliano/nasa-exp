import SwiftUI

struct SurfacePanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.large)
            .background(
                LinearGradient(
                    colors: [AppColors.surfaceHighlight.opacity(0.95), AppColors.surfaceBase.opacity(0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }
    }
}
