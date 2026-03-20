import Foundation

protocol RoversRepositoryProtocol {
    func fetchPhotos(rover: RoverName, earthDate: Date, camera: RoverCamera) async throws -> [RoverPhoto]
}

struct RoversRepository: RoversRepositoryProtocol {
    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func fetchPhotos(rover: RoverName, earthDate: Date, camera: RoverCamera) async throws -> [RoverPhoto] {
        let formattedDate = Self.apiFormatter.string(from: earthDate)
        let response: RoverPhotosResponseDTO

        do {
            response = try await client.fetch(
                RoverPhotosResponseDTO.self,
                endpoint: .roverPhotos(rover: rover.rawValue, earthDate: formattedDate, camera: camera.apiValue)
            )
        } catch NASAAPIError.serverError(let statusCode) where statusCode == 404 {
            return []
        }

        return response.photos.map(RoverPhoto.init(dto:))
    }

    private static let apiFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
