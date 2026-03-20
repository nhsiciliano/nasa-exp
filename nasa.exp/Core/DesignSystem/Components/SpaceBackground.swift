import SwiftUI

struct SpaceBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [AppColors.backgroundGlow.opacity(0.55), .clear],
                center: .topTrailing,
                startRadius: 30,
                endRadius: 340
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [AppColors.accent.opacity(0.14), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 280
            )
            .blendMode(.screen)

            Canvas { context, size in
                let stars: [CGPoint] = [
                    CGPoint(x: size.width * 0.18, y: size.height * 0.12),
                    CGPoint(x: size.width * 0.77, y: size.height * 0.16),
                    CGPoint(x: size.width * 0.36, y: size.height * 0.30),
                    CGPoint(x: size.width * 0.84, y: size.height * 0.42),
                    CGPoint(x: size.width * 0.26, y: size.height * 0.66),
                    CGPoint(x: size.width * 0.60, y: size.height * 0.78)
                ]

                for point in stars {
                    context.fill(
                        Path(ellipseIn: CGRect(x: point.x, y: point.y, width: 3, height: 3)),
                        with: .color(AppColors.textPrimary.opacity(0.35))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}
