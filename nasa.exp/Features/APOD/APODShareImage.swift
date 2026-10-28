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

    /// Downloads the image (or the poster of a video) and embeds title, caption and credit,
    /// the same metadata a copy saved to Photos carries.
    @concurrent
    static func make(for entry: APODEntry, from url: URL) async throws -> (shareImage: APODShareImage, preview: UIImage) {
        let image = try await RemoteImageLoader.loadImage(from: url)
        let jpegData = try PhotoLibrarySaver.jpegData(
            from: image,
            title: entry.title,
            caption: entry.shareMessage,
            credit: entry.shareCredit
        )

        return (APODShareImage(jpegData: jpegData, fileName: "APOD-\(entry.id).jpg"), image)
    }
}

nonisolated extension APODEntry {
    /// Caption shared next to the image: "<title> · APOD <date> · Crédito: <credit>".
    var shareText: String {
        String(localized: "\(title) · APOD \(displayDate) · Crédito: \(shareCredit)")
    }

    /// What goes with a shared or saved still. On video days the still is only the poster,
    /// so the article link, where the video plays, goes along with the caption.
    var shareMessage: String {
        guard isVideo, let shareURL else {
            return shareText
        }
        return "\(shareText)\n\(shareURL.absoluteString)"
    }

    /// The copy saved to Photos: the full original of an image, or the poster of a video.
    var photoSaveItem: PhotoSaveItem? {
        let imageURL: URL?
        if case let .image(url, hdURL) = media {
            imageURL = hdURL ?? url
        } else {
            imageURL = stillImageURL
        }

        return imageURL.map { PhotoSaveItem(imageURL: $0, title: title, caption: shareMessage, credit: shareCredit) }
    }
}
