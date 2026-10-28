import Foundation

nonisolated struct EPICEntryDTO: Decodable {
    nonisolated struct CoordinateDTO: Decodable {
        let lat: Double
        let lon: Double
    }

    let identifier: String
    let caption: String
    let image: String
    let date: String
    let centroidCoordinates: CoordinateDTO
}

nonisolated struct EPICEntry: Identifiable {
    let id: String
    let title: String
    let caption: String
    let date: Date
    let latitude: Double
    let longitude: Double
    let imageURL: URL?
    let thumbnailURL: URL?

    var displayDate: String {
        EPICEntry.displayFormatter.string(from: date)
    }

    /// `displayDate` for an explicit locale and time zone instead of the device's.
    func displayDate(locale: Locale, timeZone: TimeZone = .current) -> String {
        EPICEntry.makeDisplayFormatter(locale: locale, timeZone: timeZone).string(from: date)
    }

    var coordinateSummary: String {
        "Lat \(String(format: "%.2f", latitude)) | Lon \(String(format: "%.2f", longitude))"
    }

    /// The 1080 px JPEG of the same frame. The archive keeps `png/` (2048 px, a few MB),
    /// `jpg/` and `thumbs/` (120 px) side by side under the day's folder.
    var jpegURL: URL? {
        guard let imageURL, imageURL.pathExtension == "png" else {
            return nil
        }

        return imageURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "jpg")
            .appending(path: imageURL.deletingPathExtension().lastPathComponent)
            .appendingPathExtension("jpg")
    }

    private static let displayFormatter = makeDisplayFormatter(locale: .current, timeZone: .current)

    private static func makeDisplayFormatter(locale: Locale, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

nonisolated extension EPICEntry {
    init(dto: EPICEntryDTO) {
        let parsedDate = EPICEntry.apiFormatter.date(from: dto.date) ?? .now
        let imagePath = EPICEntry.imagePathFormatter.string(from: parsedDate)
        let archivePath = "https://epic.gsfc.nasa.gov/archive/natural/\(imagePath)"

        self.id = dto.identifier
        self.title = "EPIC - \(dto.identifier)"
        self.caption = dto.caption
        self.date = parsedDate
        self.latitude = dto.centroidCoordinates.lat
        self.longitude = dto.centroidCoordinates.lon
        self.imageURL = URL(string: "\(archivePath)/png/\(dto.image).png")
        self.thumbnailURL = URL(string: "\(archivePath)/thumbs/\(dto.image).jpg")
    }

    private static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private static let imagePathFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}
