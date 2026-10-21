import Foundation

enum AppTab: Hashable {
    case apod
    case rovers
    case epic
    case favorites

    init?(launchArgument: String) {
        switch launchArgument.lowercased() {
        case "apod": self = .apod
        case "rovers": self = .rovers
        case "epic": self = .epic
        case "favorites": self = .favorites
        default: return nil
        }
    }

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
