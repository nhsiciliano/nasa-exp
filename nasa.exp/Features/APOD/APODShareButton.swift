import SwiftUI
import UIKit

/// Shares the downloaded APOD image, or the poster on video days, with its caption, falling back
/// to the article link while the image downloads, when the download fails, or without a still.
struct APODShareButton: View {
    let entry: APODEntry
    let title: String
    let accessibilityLabel: String

    @State private var preparedImage: PreparedImage?

    var body: some View {
        Group {
            if let preparedImage, preparedImage.entryID == entry.id {
                ShareLink(
                    item: preparedImage.shareImage,
                    subject: Text(entry.title),
                    message: Text(entry.shareMessage),
                    preview: SharePreview(entry.title, image: Image(uiImage: preparedImage.preview))
                ) {
                    label
                }
            } else if let shareURL = entry.shareURL {
                ShareLink(item: shareURL, subject: Text(entry.title), message: Text(entry.shareText)) {
                    label
                }
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .task(id: entry.id) {
            await prepareImage()
        }
    }

    private var label: some View {
        ActionCapsule(title: title, systemImage: "square.and.arrow.up")
    }

    private func prepareImage() async {
        guard let imageURL = entry.stillImageURL else {
            preparedImage = nil
            return
        }

        do {
            let (shareImage, preview) = try await APODShareImage.make(for: entry, from: imageURL)
            preparedImage = PreparedImage(entryID: entry.id, shareImage: shareImage, preview: preview)
        } catch {
            // The URL share stays available, so a failed download only downgrades what gets shared.
            preparedImage = nil
        }
    }
}

private struct PreparedImage {
    let entryID: String
    let shareImage: APODShareImage
    let preview: UIImage
}
