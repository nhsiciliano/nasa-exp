import CoreTransferable
import UIKit
import UniformTypeIdentifiers

/// Downloaded APOD image ready to hand to the share sheet as a JPEG file.
nonisolated struct APODShareImage: Transferable {
    let jpegData: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { shareImage in
            shareImage.jpegData
        }
        .suggestedFileName { $0.fileName }
    }

    @concurrent
    static func make(for entry: APODEntry, from url: URL) async throws -> (shareImage: APODShareImage, preview: UIImage) {
        let image = try await RemoteImageLoader.loadImage(from: url)

        guard let jpegData = image.jpegData(compressionQuality: 0.9) else {
            throw RemoteImageError.undecodableImage
        }

        return (APODShareImage(jpegData: jpegData, fileName: "APOD-\(entry.id).jpg"), image)
    }
}

nonisolated extension APODEntry {
    /// Caption shared next to the image: "<title> · APOD <date> · Crédito: <credit>".
    var shareText: String {
        "\(title) · APOD \(displayDate) · Crédito: \(shareCredit)"
    }

    var shareCredit: String {
        let credit = (copyright ?? "")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")

        return credit.isEmpty ? "NASA" : credit
    }
}
