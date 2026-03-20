import Foundation

enum RoverName: String, CaseIterable, Identifiable {
    case curiosity
    case opportunity
    case spirit
    case perseverance

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

enum RoverCamera: String, CaseIterable, Identifiable {
    case all
    case fhaz = "FHAZ"
    case rhaz = "RHAZ"
    case navcam = "NAVCAM"
    case mast = "MAST"
    case chemcam = "CHEMCAM"
    case mahli = "MAHLI"
    case mardi = "MARDI"
    case pancam = "PANCAM"
    case minites = "MINITES"
    case mcz = "MCZ"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todas"
        case .fhaz: return "Front Hazcam"
        case .rhaz: return "Rear Hazcam"
        case .navcam: return "Navcam"
        case .mast: return "Mast"
        case .chemcam: return "Chemcam"
        case .mahli: return "MAHLI"
        case .mardi: return "MARDI"
        case .pancam: return "Pancam"
        case .minites: return "MiniTES"
        case .mcz: return "Mastcam-Z"
        }
    }

    var apiValue: String? {
        self == .all ? nil : rawValue.lowercased()
    }

    static func options(for rover: RoverName) -> [RoverCamera] {
        switch rover {
        case .curiosity:
            return [.all, .fhaz, .rhaz, .mast, .chemcam, .mahli, .mardi, .navcam]
        case .opportunity, .spirit:
            return [.all, .fhaz, .rhaz, .navcam, .pancam, .minites]
        case .perseverance:
            return [.all, .fhaz, .rhaz, .mcz, .navcam]
        }
    }
}

struct RoverPhotosResponseDTO: Decodable {
    let photos: [RoverPhotoDTO]
}

struct RoverPhotoDTO: Decodable {
    struct CameraDTO: Decodable {
        let name: String
        let fullName: String
    }

    struct RoverDTO: Decodable {
        let name: String
        let status: String
        let launchDate: String
        let landingDate: String
    }

    let id: Int
    let imgSrc: String
    let earthDate: String
    let camera: CameraDTO
    let rover: RoverDTO
}

struct RoverPhoto: Identifiable {
    let id: Int
    let imageURL: URL?
    let earthDate: Date
    let cameraName: String
    let cameraFullName: String
    let roverName: String

    var displayDate: String {
        RoverPhoto.displayFormatter.string(from: earthDate)
    }

    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            contentType: .rover,
            remoteID: "\(id)",
            title: "\(roverName) - \(cameraName)",
            subtitle: displayDate,
            details: cameraFullName,
            mediaURL: imageURL
        )
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        return formatter
    }()
}

extension RoverPhoto {
    init(dto: RoverPhotoDTO) {
        self.id = dto.id
        self.imageURL = URL(string: dto.imgSrc)
        self.earthDate = RoverPhoto.apiFormatter.date(from: dto.earthDate) ?? .now
        self.cameraName = dto.camera.name
        self.cameraFullName = dto.camera.fullName
        self.roverName = dto.rover.name
    }

    init(favoriteItem: FavoriteItem) {
        self.id = Int(favoriteItem.remoteID) ?? 0
        self.imageURL = favoriteItem.mediaURL
        self.earthDate = .now
        self.cameraName = favoriteItem.title.components(separatedBy: " - ").last ?? "Rover"
        self.cameraFullName = favoriteItem.details
        self.roverName = favoriteItem.title.components(separatedBy: " - ").first ?? "Rover"
    }

    private static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
