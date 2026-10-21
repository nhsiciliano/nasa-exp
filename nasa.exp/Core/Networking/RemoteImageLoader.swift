import UIKit

enum RemoteImageError: LocalizedError {
    case invalidResponse(statusCode: Int?)
    case undecodableImage

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(statusCode):
            if let statusCode {
                return String(localized: "No se pudo descargar la imagen (HTTP \(statusCode)).")
            }
            return String(localized: "No se pudo descargar la imagen.")
        case .undecodableImage:
            return String(localized: "El archivo descargado no es una imagen válida.")
        }
    }
}

/// Downloads full images when a view needs the bitmap itself (sharing, zooming) rather than `AsyncImage`.
nonisolated enum RemoteImageLoader {
    @concurrent
    static func loadImage(from url: URL, session: URLSession = .shared) async throws -> UIImage {
        let (data, response) = try await session.data(from: url)

        let statusCode = (response as? HTTPURLResponse)?.statusCode
        guard let statusCode, (200...299).contains(statusCode) else {
            throw RemoteImageError.invalidResponse(statusCode: statusCode)
        }

        guard let image = UIImage(data: data)?.preparingForDisplay() ?? UIImage(data: data) else {
            throw RemoteImageError.undecodableImage
        }

        return image
    }
}
