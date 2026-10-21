import SwiftUI

enum AppTypography {
    static let display = Font.custom("AvenirNext-Bold", size: 36, relativeTo: .largeTitle)
    static let largeTitle = Font.custom("AvenirNext-Bold", size: 30, relativeTo: .largeTitle)
    static let title2 = Font.custom("AvenirNext-DemiBold", size: 24, relativeTo: .title2)
    static let title3 = Font.custom("AvenirNext-DemiBold", size: 20, relativeTo: .title3)
    static let body = Font.custom("AvenirNext-Regular", size: 16, relativeTo: .body)
    static let bodyStrong = Font.custom("AvenirNext-DemiBold", size: 16, relativeTo: .body)
    static let caption = Font.custom("AvenirNext-Medium", size: 12, relativeTo: .caption)
    static let micro = Font.custom("AvenirNext-DemiBold", size: 11, relativeTo: .caption2)
}
