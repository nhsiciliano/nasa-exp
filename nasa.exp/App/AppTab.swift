import Foundation

nonisolated enum AppTab: String {
    case apod
    case rovers
    case epic
    case favorites

    /// URL scheme registered in `Config/Info.plist`. The widget opens the app with `nasaexp://apod`.
    static let urlScheme = "nasaexp"

    init?(launchArgument: String) {
        self.init(rawValue: launchArgument.lowercased())
    }

    /// Parses `nasaexp://<tab>` deep links, using the same tab names as `-initialTab`.
    init?(url: URL) {
        guard url.scheme?.lowercased() == AppTab.urlScheme, let host = url.host() else {
            return nil
        }

        self.init(launchArgument: host)
    }

    var deepLinkURL: URL? {
        URL(string: "\(AppTab.urlScheme)://\(rawValue)")
    }

    var title: String {
        switch self {
        case .apod:
            return String(localized: "Hoy")
        case .rovers:
            return "Rovers"
        case .epic:
            return String(localized: "Tierra")
        case .favorites:
            return String(localized: "Favoritos")
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
