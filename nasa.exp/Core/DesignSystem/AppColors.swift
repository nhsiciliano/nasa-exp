import SwiftUI

enum AppColors {
    static let backgroundTop = Color(red: 0.01, green: 0.03, blue: 0.09)
    static let backgroundBottom = Color(red: 0.01, green: 0.01, blue: 0.05)
    static let backgroundGlow = Color(red: 0.07, green: 0.20, blue: 0.34)

    static let surfaceBase = Color(red: 0.04, green: 0.08, blue: 0.16)
    static let surfaceElevated = Color(red: 0.07, green: 0.12, blue: 0.22)
    static let surfaceHighlight = Color(red: 0.10, green: 0.16, blue: 0.28)
    static let cardBackground = surfaceElevated

    static let accent = Color(red: 0.22, green: 0.86, blue: 0.96)
    static let accentSecondary = Color(red: 1.0, green: 0.73, blue: 0.30)
    static let accentMuted = Color(red: 0.52, green: 0.89, blue: 0.95)

    static let textPrimary = Color(red: 0.95, green: 0.98, blue: 1.0)
    static let textSecondary = Color(red: 0.74, green: 0.82, blue: 0.92)
    static let textTertiary = Color(red: 0.51, green: 0.61, blue: 0.73)

    static let border = Color(red: 0.35, green: 0.55, blue: 0.74).opacity(0.28)
    static let borderStrong = Color(red: 0.42, green: 0.88, blue: 0.96).opacity(0.45)
}
