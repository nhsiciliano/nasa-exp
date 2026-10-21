import SwiftUI
import SwiftData

struct RoverPhotoDetailView: View {
    let photo: RoverPhoto
    /// False when the photo was rebuilt from its favorite, whose fallback values must not be stored.
    var refreshesStoredFavorite = true
    @State private var isFavorite = false
    @State private var showsFullscreenImage = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Button {
                        showsFullscreenImage = true
                    } label: {
                        photoView
                    }
                    .buttonStyle(.plain)
                    .disabled(photo.imageURL == nil)
                    .accessibilityLabel("Abrir foto a pantalla completa")
                    .accessibilityHint("Permite hacer zoom con pellizco o doble toque")

                    SectionHeader(title: "\(photo.roverName) · \(photo.cameraName)", subtitle: photo.displayDate)

                    HStack(spacing: AppSpacing.small) {
                        InfoPill(text: String(localized: "ROVER FEED"))
                        InfoPill(text: photo.solLabel.uppercased())
                        if !photo.instrument.isEmpty {
                            InfoPill(text: photo.instrument)
                        }
                    }

                    if !photo.caption.isEmpty {
                        Text(photo.caption)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                            .lineSpacing(4)
                            .textSelection(.enabled)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("Cámara: \(photo.cameraFullName)")
                        Text("Misión: \(photo.rover.missionName)")
                        Text("Crédito: \(photo.credit)")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                    if let shareURL = photo.imageURL {
                        ShareLink(item: shareURL) {
                            ActionCapsule(title: String(localized: "Compartir imagen"), systemImage: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Compartir foto del rover")
                    }

                    if let photoSaveItem {
                        SaveToPhotosButton(item: photoSaveItem)
                    }

                    Button {
                        toggleFavorite()
                    } label: {
                        ActionCapsule(
                            title: isFavorite ? String(localized: "Quitar de favoritos") : String(localized: "Guardar en favoritos"),
                            systemImage: isFavorite ? "star.slash.fill" : "star.fill",
                            isEmphasized: false
                        )
                    }
                    .accessibilityHint(isFavorite ? String(localized: "Elimina esta foto de tus favoritos") : String(localized: "Guarda esta foto en tus favoritos"))
                }
                .padding(AppSpacing.large)
            }
        }
        .navigationTitle("Detalle Rover")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorite = refreshesStoredFavorite
                ? FavoriteStore.refreshIfFavorite(photo.favoriteDraft, in: modelContext)
                : FavoriteStore.contains(photo.favoriteDraft, in: modelContext)
        }
        .fullScreenCover(isPresented: $showsFullscreenImage) {
            FullscreenImageViewer(
                url: photo.imageURL,
                accessibilityLabel: String(localized: "Foto de \(photo.roverName), \(photo.cameraFullName), \(photo.solLabel)")
            )
        }
    }

    private var photoSaveItem: PhotoSaveItem? {
        guard let imageURL = photo.imageURL else {
            return nil
        }

        let title = "\(photo.roverName) · \(photo.cameraFullName)"
        return PhotoSaveItem(
            imageURL: imageURL,
            title: title,
            caption: String(localized: "\(title) · \(photo.displayDate) · Crédito: \(photo.credit)"),
            credit: photo.credit
        )
    }

    private var photoView: some View {
        AsyncImage(url: photo.imageURL) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure:
                HeroCard(
                    title: String(localized: "No se pudo cargar la foto"),
                    subtitle: String(localized: "Intentá nuevamente en unos segundos."),
                    symbolName: "photo.badge.exclamationmark"
                )
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .tint(AppColors.accent)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            @unknown default:
                EmptyView()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        }
    }

    private func toggleFavorite() {
        if isFavorite {
            FavoriteStore.remove(photo.favoriteDraft, in: modelContext)
        } else {
            FavoriteStore.upsert(photo.favoriteDraft, in: modelContext)
        }

        isFavorite.toggle()
    }
}
