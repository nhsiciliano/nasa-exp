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

    var displayDate: String {
        EPICEntry.displayFormatter.string(from: date)
    }

    var coordinateSummary: String {
        "Lat \(String(format: "%.2f", latitude)) | Lon \(String(format: "%.2f", longitude))"
    }

    var favoriteDraft: FavoriteDraft {
        FavoriteDraft(
            contentType: .epic,
            remoteID: id,
            title: title,
            subtitle: displayDate,
            details: caption,
            mediaURL: imageURL
        )
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

nonisolated extension EPICEntry {
    init(dto: EPICEntryDTO) {
        let parsedDate = EPICEntry.apiFormatter.date(from: dto.date) ?? .now
        let imagePath = EPICEntry.imagePathFormatter.string(from: parsedDate)
        let imageURLString = "https://epic.gsfc.nasa.gov/archive/natural/\(imagePath)/png/\(dto.image).png?api_key=\(NASAEnvironment.apiKey)"

        self.id = dto.identifier
        self.title = "EPIC - \(dto.identifier)"
        self.caption = dto.caption
        self.date = parsedDate
        self.latitude = dto.centroidCoordinates.lat
        self.longitude = dto.centroidCoordinates.lon
        self.imageURL = URL(string: imageURLString)
    }

    init(favoriteItem: FavoriteItem) {
        self.id = favoriteItem.remoteID
        self.title = favoriteItem.title
        self.caption = favoriteItem.details
        self.date = .now
        self.latitude = 0
        self.longitude = 0
        self.imageURL = favoriteItem.mediaURL
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
