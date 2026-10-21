import SwiftUI
import UIKit

/// Black full-screen image viewer with pinch and double-tap zoom, meant for `fullScreenCover`.
struct FullscreenImageViewer: View {
    let url: URL?
    let accessibilityLabel: String

    @Environment(\.dismiss) private var dismiss
    @State private var loadState: LoadState = .loading

    private enum LoadState {
        case loading
        case loaded(UIImage)
        case failed
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            content

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .frame(width: 44, height: 44)
                    .padding(AppSpacing.medium)
            }
            .accessibilityLabel("Cerrar imagen a pantalla completa")
            .accessibilitySortPriority(1)
        }
        .accessibilityAction(.escape) {
            dismiss()
        }
        .task(id: url) {
            await loadImage()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            ProgressView()
                .tint(Color.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case let .loaded(image):
            ZoomableImageView(image: image, accessibilityLabel: accessibilityLabel)
                .ignoresSafeArea()
        case .failed:
            VStack(spacing: AppSpacing.medium) {
                Text("No se pudo mostrar la imagen")
                    .font(AppTypography.body)
                    .foregroundStyle(Color.white)

                Button {
                    Task {
                        await loadImage()
                    }
                } label: {
                    Label("Reintentar", systemImage: "arrow.clockwise")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(Color.white)
                        .frame(minHeight: 44)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func loadImage() async {
        guard let url else {
            loadState = .failed
            return
        }

        loadState = .loading
        do {
            loadState = .loaded(try await RemoteImageLoader.loadImage(from: url))
        } catch where Task.isCancelled {
            return
        } catch {
            loadState = .failed
        }
    }
}
