import Foundation
import ImageIO
import Photos
import UIKit
import UniformTypeIdentifiers

/// What gets written to the photo library: the remote image plus the caption and credit
/// stored as IPTC/TIFF metadata. ImageIO drops some keys depending on the platform, so the
/// credit is written to every field that may carry it; Photos shows the IPTC caption.
nonisolated struct PhotoSaveItem: Equatable {
    let imageURL: URL
    let title: String
    let caption: String
    let credit: String
}

enum PhotoLibrarySaveError: LocalizedError {
    case accessDenied
    case encodingFailed
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return String(localized: "La app no tiene permiso para guardar en Fotos. Podés habilitarlo en Ajustes.")
        case .encodingFailed:
            return String(localized: "No se pudo preparar la imagen para guardarla.")
        case let .saveFailed(error):
            return String(localized: "Fotos no pudo guardar la imagen: \(error.localizedDescription)")
        }
    }
}

nonisolated enum PhotoLibrarySaver {
    /// Downloads the image, embeds title and credit, and adds it to Photos with add-only access.
    @concurrent
    static func save(_ item: PhotoSaveItem) async throws {
        try await requestAddAccess()

        let image = try await RemoteImageLoader.loadImage(from: item.imageURL)
        let data = try jpegData(from: image, title: item.title, caption: item.caption, credit: item.credit)

        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }
        } catch {
            throw PhotoLibrarySaveError.saveFailed(error)
        }
    }

    static func jpegData(from image: UIImage, title: String, caption: String, credit: String) throws -> Data {
        guard let cgImage = image.cgImage else {
            throw PhotoLibrarySaveError.encodingFailed
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw PhotoLibrarySaveError.encodingFailed
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.92,
            kCGImagePropertyTIFFDictionary: [
                kCGImagePropertyTIFFImageDescription: caption,
                kCGImagePropertyTIFFArtist: credit,
                kCGImagePropertyTIFFCopyright: credit
            ],
            kCGImagePropertyIPTCDictionary: [
                kCGImagePropertyIPTCObjectName: title,
                kCGImagePropertyIPTCCaptionAbstract: caption,
                kCGImagePropertyIPTCCredit: credit,
                kCGImagePropertyIPTCByline: [credit],
                kCGImagePropertyIPTCCopyrightNotice: credit
            ]
        ]
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw PhotoLibrarySaveError.encodingFailed
        }

        return output as Data
    }

    private static func requestAddAccess() async throws {
        var status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .notDetermined {
            status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        }

        guard status == .authorized || status == .limited else {
            throw PhotoLibrarySaveError.accessDenied
        }
    }
}
