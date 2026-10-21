import Foundation

/// Rovers with a live raw-image feed on `mars.nasa.gov`.
/// Spirit and Opportunity are finished missions whose photo API no longer exists.
nonisolated enum RoverName: String, CaseIterable, Identifiable {
    case curiosity
    case perseverance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .curiosity:
            return "Curiosity"
        case .perseverance:
            return "Perseverance"
        }
    }

    var missionName: String {
        switch self {
        case .curiosity:
            return "Mars Science Laboratory"
        case .perseverance:
            return "Mars 2020"
        }
    }

    var landingSummary: String {
        switch self {
        case .curiosity:
            return "Cráter Gale · aterrizó en 2012"
        case .perseverance:
            return "Cráter Jezero · aterrizó en 2021"
        }
    }
}

nonisolated enum RoverCamera: String, CaseIterable, Identifiable {
    case all
    case fhaz
    case rhaz
    case navcam
    case mast
    case chemcam
    case mahli
    case mardi
    case mastcamZ
    case supercam
    case watson
    case pixl
    case skycam

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "Todas"
        case .fhaz: return "Front Hazcam"
        case .rhaz: return "Rear Hazcam"
        case .navcam: return "Navcam"
        case .mast: return "Mastcam"
        case .chemcam: return "ChemCam"
        case .mahli: return "MAHLI"
        case .mardi: return "MARDI"
        case .mastcamZ: return "Mastcam-Z"
        case .supercam: return "SuperCam"
        case .watson: return "WATSON"
        case .pixl: return "PIXL"
        case .skycam: return "SkyCam"
        }
    }

    var fullName: String {
        switch self {
        case .all: return "Todas las cámaras"
        case .fhaz: return "Front Hazard Avoidance Camera"
        case .rhaz: return "Rear Hazard Avoidance Camera"
        case .navcam: return "Navigation Camera"
        case .mast: return "Mast Camera"
        case .chemcam: return "Chemistry & Camera Remote Micro-Imager"
        case .mahli: return "Mars Hand Lens Imager"
        case .mardi: return "Mars Descent Imager"
        case .mastcamZ: return "Mastcam-Z Zoomable Mast Camera"
        case .supercam: return "SuperCam Remote Micro-Imager"
        case .watson: return "SHERLOC WATSON Camera"
        case .pixl: return "PIXL Micro Context Camera"
        case .skycam: return "MEDA SkyCam"
        }
    }

    /// Raw instrument identifiers used by the `mars.nasa.gov` feeds for this camera on a given rover.
    func instruments(for rover: RoverName) -> [String] {
        switch (rover, self) {
        case (_, .all):
            return []

        case (.curiosity, .fhaz):
            return ["FHAZ_LEFT_A", "FHAZ_RIGHT_A", "FHAZ_LEFT_B", "FHAZ_RIGHT_B"]
        case (.curiosity, .rhaz):
            return ["RHAZ_LEFT_A", "RHAZ_RIGHT_A", "RHAZ_LEFT_B", "RHAZ_RIGHT_B"]
        case (.curiosity, .navcam):
            return ["NAV_LEFT_A", "NAV_RIGHT_A", "NAV_LEFT_B", "NAV_RIGHT_B"]
        case (.curiosity, .mast):
            return ["MAST_LEFT", "MAST_RIGHT"]
        case (.curiosity, .chemcam):
            return ["CHEMCAM_RMI"]
        case (.curiosity, .mahli):
            return ["MAHLI"]
        case (.curiosity, .mardi):
            return ["MARDI"]

        case (.perseverance, .fhaz):
            return ["FRONT_HAZCAM_LEFT_A", "FRONT_HAZCAM_RIGHT_A", "FRONT_HAZCAM_LEFT_B", "FRONT_HAZCAM_RIGHT_B"]
        case (.perseverance, .rhaz):
            return ["REAR_HAZCAM_LEFT", "REAR_HAZCAM_RIGHT"]
        case (.perseverance, .navcam):
            return ["NAVCAM_LEFT", "NAVCAM_RIGHT"]
        case (.perseverance, .mastcamZ):
            return ["MCZ_LEFT", "MCZ_RIGHT"]
        case (.perseverance, .supercam):
            return ["SUPERCAM_RMI"]
        case (.perseverance, .watson):
            return ["SHERLOC_WATSON"]
        case (.perseverance, .pixl):
            return ["PIXL_MCC"]
        case (.perseverance, .skycam):
            return ["SKYCAM"]

        default:
            return []
        }
    }

    /// Value for the feed `search` parameter, or `nil` when no camera filter applies.
    func searchValue(for rover: RoverName) -> String? {
        let instruments = instruments(for: rover)
        return instruments.isEmpty ? nil : instruments.joined(separator: "|")
    }

    static func options(for rover: RoverName) -> [RoverCamera] {
        switch rover {
        case .curiosity:
            return [.all, .navcam, .mast, .fhaz, .rhaz, .chemcam, .mahli, .mardi]
        case .perseverance:
            return [.all, .navcam, .mastcamZ, .fhaz, .rhaz, .supercam, .watson, .pixl, .skycam]
        }
    }

    static func camera(matching instrument: String, rover: RoverName) -> RoverCamera? {
        options(for: rover).first { $0.instruments(for: rover).contains(instrument) }
    }
}

// MARK: - Feed DTOs

/// `https://mars.nasa.gov/api/v1/raw_image_items/` (Curiosity / MSL).
nonisolated struct MSLRawImagesResponseDTO: Decodable {
    let items: [MSLRawImageDTO]
    let more: Bool?
    let total: Int?
    let page: Int?
}

nonisolated struct MSLRawImageDTO: Decodable {
    nonisolated struct ExtendedDTO: Decodable {
        let sampleType: String?
    }

    let id: Int
    let imageid: String
    let sol: Int
    let instrument: String
    let httpsUrl: String
    let dateTaken: String?
    let title: String?
    let description: String?
    let imageCredit: String?
    let isThumbnail: Bool?
    let extended: ExtendedDTO?
}

/// `https://mars.nasa.gov/rss/api/?feed=raw_images&category=mars2020` (Perseverance / Mars 2020).
nonisolated struct Mars2020RawImagesResponseDTO: Decodable {
    let images: [Mars2020RawImageDTO]
    let totalResults: Int?
    let page: Int?
    let perPage: Int?
}

nonisolated struct Mars2020RawImageDTO: Decodable {
    nonisolated struct CameraDTO: Decodable {
        let instrument: String
    }

    nonisolated struct ImageFilesDTO: Decodable {
        let small: String?
        let medium: String?
        let large: String?
        let fullRes: String?
    }

    let imageid: String
    let sol: Int
    let camera: CameraDTO
    let imageFiles: ImageFilesDTO
    let title: String?
    let caption: String?
    let credit: String?
    let dateTakenUtc: String?
    let sampleType: String?
}

// MARK: - Domain

nonisolated struct RoverPhotoPage {
    let photos: [RoverPhoto]
    let total: Int
    let hasMore: Bool
}

nonisolated struct RoverPhoto: Identifiable, Hashable {
    let id: String
    let rover: RoverName
    let sol: Int
    let instrument: String
    let cameraName: String
    let cameraFullName: String
    let thumbnailURL: URL?
    let imageURL: URL?
    let earthDate: Date?
    let caption: String
    let credit: String

    /// Display text restored from a stored favorite when the original date is unavailable.
    private let storedDisplayDate: String?

    var roverName: String { rover.title }

    var solLabel: String { "Sol \(sol)" }

    var displayDate: String {
        if let storedDisplayDate {
            return storedDisplayDate
        }

        guard let earthDate else {
            return solLabel
        }

        return "\(solLabel) · \(RoverPhoto.displayFormatter.string(from: earthDate))"
    }

    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            contentType: .rover,
            remoteID: id,
            title: "\(roverName) - \(cameraName)",
            subtitle: displayDate,
            details: caption,
            mediaURL: imageURL
        )
    }

    init(
        id: String,
        rover: RoverName,
        sol: Int,
        instrument: String,
        cameraName: String,
        cameraFullName: String,
        thumbnailURL: URL?,
        imageURL: URL?,
        earthDate: Date?,
        caption: String,
        credit: String,
        storedDisplayDate: String? = nil
    ) {
        self.id = id
        self.rover = rover
        self.sol = sol
        self.instrument = instrument
        self.cameraName = cameraName
        self.cameraFullName = cameraFullName
        self.thumbnailURL = thumbnailURL
        self.imageURL = imageURL
        self.earthDate = earthDate
        self.caption = caption
        self.credit = credit
        self.storedDisplayDate = storedDisplayDate
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        return formatter
    }()
}

nonisolated extension RoverPhoto {
    static let defaultCredit = "NASA/JPL-Caltech"

    init(dto: MSLRawImageDTO) {
        let rover = RoverName.curiosity
        let camera = RoverCamera.camera(matching: dto.instrument, rover: rover)
        let imageURL = URL(string: dto.httpsUrl)

        self.init(
            id: "msl-\(dto.id)",
            rover: rover,
            sol: dto.sol,
            instrument: dto.instrument,
            cameraName: camera?.title ?? RoverPhoto.humanized(instrument: dto.instrument),
            cameraFullName: camera?.fullName ?? dto.instrument,
            thumbnailURL: imageURL,
            imageURL: imageURL,
            earthDate: RoverPhoto.parseUTCDate(dto.dateTaken),
            caption: dto.description ?? dto.title ?? "",
            credit: dto.imageCredit ?? RoverPhoto.defaultCredit
        )
    }

    init(dto: Mars2020RawImageDTO) {
        let rover = RoverName.perseverance
        let camera = RoverCamera.camera(matching: dto.camera.instrument, rover: rover)
        let files = dto.imageFiles
        let fullURL = URL(string: files.large ?? files.medium ?? files.fullRes ?? files.small ?? "")
        let thumbnailURL = URL(string: files.small ?? files.medium ?? files.large ?? "")

        self.init(
            id: "m2020-\(dto.imageid)",
            rover: rover,
            sol: dto.sol,
            instrument: dto.camera.instrument,
            cameraName: camera?.title ?? RoverPhoto.humanized(instrument: dto.camera.instrument),
            cameraFullName: camera?.fullName ?? dto.camera.instrument,
            thumbnailURL: thumbnailURL ?? fullURL,
            imageURL: fullURL,
            earthDate: RoverPhoto.parseUTCDate(dto.dateTakenUtc),
            caption: dto.caption ?? dto.title ?? "",
            credit: dto.credit ?? RoverPhoto.defaultCredit
        )
    }

    init(favoriteItem: FavoriteItem) {
        let titleParts = favoriteItem.title.components(separatedBy: " - ")
        let roverTitle = titleParts.first ?? ""
        let rover: RoverName = favoriteItem.remoteID.hasPrefix("m2020-") || roverTitle == RoverName.perseverance.title
            ? .perseverance
            : .curiosity
        let cameraName = titleParts.count > 1 ? titleParts.dropFirst().joined(separator: " - ") : "Rover"

        self.init(
            id: favoriteItem.remoteID,
            rover: rover,
            sol: RoverPhoto.parseSol(from: favoriteItem.subtitle) ?? 0,
            instrument: "",
            cameraName: cameraName,
            cameraFullName: cameraName,
            thumbnailURL: favoriteItem.mediaURL,
            imageURL: favoriteItem.mediaURL,
            earthDate: nil,
            caption: favoriteItem.details,
            credit: RoverPhoto.defaultCredit,
            storedDisplayDate: favoriteItem.subtitle
        )
    }

    private static func humanized(instrument: String) -> String {
        instrument
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    private static func parseSol(from text: String) -> Int? {
        guard let range = text.range(of: #"Sol (\d+)"#, options: .regularExpression) else {
            return nil
        }

        let digits = text[range].filter(\.isNumber)
        return Int(digits)
    }

    static func parseUTCDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else {
            return nil
        }

        for formatter in utcFormatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    private static let utcFormatters: [DateFormatter] = [
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd'T'HH:mm:ss"
    ].map { format in
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }
}
