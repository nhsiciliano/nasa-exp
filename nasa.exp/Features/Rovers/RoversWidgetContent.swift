import CoreGraphics
import Foundation
import UIKit

/// What the Rovers widget shows: the newest raw photo from either rover.
nonisolated struct RoversWidgetContent {
    let roverName: String
    let cameraName: String
    /// "Sol 2022 · Oct 28, 2026".
    let detail: String
    let credit: String
    /// `nil` only in the gallery placeholder.
    let image: UIImage?
}

/// Loads the newest photo of Perseverance and of Curiosity at the same time and keeps the most
/// recent one. The Mars 2020 feed can take 15 s on queries the server has not cached, so a rover
/// whose feed fails or times out is skipped instead of failing the widget.
/// Shared with the widget extension; it lives in the app target so the unit tests can reach it.
nonisolated struct RoversWidgetContentLoader {
    typealias DataLoader = @Sendable (URL) async throws -> Data

    /// Below the default 30 s, so one slow feed still leaves time for the image download.
    static let requestTimeout: TimeInterval = 20

    private let loadData: DataLoader

    init(loadData: @escaping DataLoader = { url in
        try await NASAClient().fetchData(url: url, timeout: RoversWidgetContentLoader.requestTimeout)
    }) {
        self.loadData = loadData
    }

    func load(now: Date, imagePixelSize: CGSize) async -> PhotoWidgetUpdate<RoversWidgetContent> {
        async let perseverance = latestPhoto(of: .perseverance)
        async let curiosity = latestPhoto(of: .curiosity)
        let photos = await [perseverance, curiosity].compactMap { $0 }

        // `max(by:)` keeps the first of equal elements, so Perseverance wins a tie or missing dates.
        guard let photo = photos.max(by: { ($0.earthDate ?? .distantPast) < ($1.earthDate ?? .distantPast) }),
              let imageURL = photo.imageURL else {
            return .failed(now: now)
        }

        do {
            let image = try await PhotoWidgetImage.load(imageURL, filling: imagePixelSize, using: loadData)
            let content = RoversWidgetContent(
                roverName: photo.roverName,
                cameraName: photo.cameraName,
                detail: photo.displayDate,
                credit: photo.credit,
                image: image
            )
            return .loaded(content, now: now)
        } catch {
            return .failed(now: now)
        }
    }

    /// The rover's newest photo, or `nil` when its feed fails: the other rover can still fill the widget.
    private func latestPhoto(of rover: RoverName) async -> RoverPhoto? {
        do {
            return try await fetchLatestPhoto(of: rover)
        } catch {
            return nil
        }
    }

    private func fetchLatestPhoto(of rover: RoverName) async throws -> RoverPhoto {
        // The same query as `RoversRepository.fetchLatestSol`, so it shares the feed's server cache.
        let request = MarsRawImagesRequest(rover: rover, sol: nil, camera: .all, page: 0, pageSize: 1)
        guard let url = request.url else {
            throw NASAAPIError.invalidRequest
        }

        let data = try await loadData(url)
        switch rover {
        case .curiosity:
            let response = try NASAClient.decode(MSLRawImagesResponseDTO.self, from: data)
            guard let item = response.items.first else {
                throw PhotoWidgetError.noPhotos
            }
            return RoverPhoto(dto: item)

        case .perseverance:
            let response = try NASAClient.decode(Mars2020RawImagesResponseDTO.self, from: data)
            guard let image = response.images.first else {
                throw PhotoWidgetError.noPhotos
            }
            return RoverPhoto(dto: image)
        }
    }
}
