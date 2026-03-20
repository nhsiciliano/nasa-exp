import Foundation

enum AppTab: Hashable {
    case apod
    case rovers
    case epic
    case favorites

    var title: String {
        switch self {
        case .apod:
            return "Hoy"
        case .rovers:
            return "Rovers"
        case .epic:
            return "Tierra"
        case .favorites:
            return "Favoritos"
        }
    }

    var systemImage: String {
        switch self {
        case .apod:
            return "sparkles.tv"
        case .rovers:
            return "antenna.radiowaves.left.and.right"
        case .epic:
            return "globe.americas"
        case .favorites:
            return "star.fill"
        }
    }
}
