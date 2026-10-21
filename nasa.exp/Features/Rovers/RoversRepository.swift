import Foundation

nonisolated protocol RoversRepositoryProtocol {
    func fetchLatestSol(for rover: RoverName) async throws -> Int
    func fetchPhotos(rover: RoverName, sol: Int, camera: RoverCamera, page: Int) async throws -> RoverPhotoPage
}

nonisolated struct RoversRepository: RoversRepositoryProtocol {
    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func fetchLatestSol(for rover: RoverName) async throws -> Int {
        let request = MarsRawImagesRequest(rover: rover, sol: nil, camera: .all, page: 0, pageSize: 1)
        guard let url = request.url else {
            throw NASAAPIError.invalidRequest
        }

        switch rover {
        case .curiosity:
            let response = try await client.fetch(MSLRawImagesResponseDTO.self, url: url)
            guard let latest = response.items.first else {
                throw NASAAPIError.invalidResponse
            }
            return latest.sol

        case .perseverance:
            let response = try await client.fetch(Mars2020RawImagesResponseDTO.self, url: url)
            guard let latest = response.images.first else {
                throw NASAAPIError.invalidResponse
            }
            return latest.sol
        }
    }

    func fetchPhotos(rover: RoverName, sol: Int, camera: RoverCamera, page: Int) async throws -> RoverPhotoPage {
        let request = MarsRawImagesRequest(rover: rover, sol: sol, camera: camera, page: page)
        guard let url = request.url else {
            throw NASAAPIError.invalidRequest
        }

        switch rover {
        case .curiosity:
            let response = try await client.fetch(MSLRawImagesResponseDTO.self, url: url)
            let photos = response.items.map(RoverPhoto.init(dto:))
            return RoverPhotoPage(
                photos: photos,
                total: response.total ?? photos.count,
                hasMore: response.more ?? (photos.count == request.pageSize)
            )

        case .perseverance:
            let response = try await client.fetch(Mars2020RawImagesResponseDTO.self, url: url)
            let photos = response.images.map(RoverPhoto.init(dto:))
            let loadedCount = (page + 1) * request.pageSize
            let hasMore: Bool
            if let total = response.totalResults {
                hasMore = loadedCount < total
            } else {
                hasMore = photos.count == request.pageSize
            }
            return RoverPhotoPage(
                photos: photos,
                total: response.totalResults ?? photos.count,
                hasMore: hasMore
            )
        }
    }
}
