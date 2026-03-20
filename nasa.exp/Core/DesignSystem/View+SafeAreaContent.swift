import SwiftUI

extension View {
    func appScreenChromeSpacing() -> some View {
        safeAreaPadding(.top, AppSpacing.large)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 88)
            }
    }
}
