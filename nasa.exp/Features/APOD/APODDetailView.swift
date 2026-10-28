import SwiftUI
import SwiftData

struct APODDetailView: View {
    let entry: APODEntry
    /// False when the entry was rebuilt from its favorite, whose fallback values must not be stored.
    var refreshesStoredFavorite = true

    @State private var showsFullscreenImage = false
    @State private var isFavorite = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    SectionHeader(title: entry.title, subtitle: entry.displayDate)

                    HStack(spacing: AppSpacing.small) {
                        InfoPill(text: String(localized: "DEEP SPACE"))
                        InfoPill(text: String(localized: "EDITORIAL"))
                    }

                    mediaView

                    HStack(spacing: AppSpacing.small) {
                        InfoPill(text: "APOD")
                        if entry.copyright != nil {
                            InfoPill(text: String(localized: "Con créditos"))
                        }
                    }

                    if let copyright = entry.copyright, !copyright.isEmpty {
                        Text("Crédito: \(copyright)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(entry.explanation)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .accessibilityLabel("Descripción completa. \(entry.explanation)")

                    APODShareButton(
                        entry: entry,
                        title: String(localized: "Compartir APOD"),
                        accessibilityLabel: String(localized: "Compartir APOD")
                    )

                    if let photoSaveItem = entry.photoSaveItem {
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
                    .accessibilityHint(isFavorite ? String(localized: "Elimina este contenido de tu archivo personal") : String(localized: "Guarda este contenido en tu archivo personal"))
                }
                .padding(AppSpacing.large)
            }
        }
        .navigationTitle("Detalle APOD")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorite = refreshesStoredFavorite
                ? FavoriteStore.refreshIfFavorite(entry.favoriteDraft, in: modelContext)
                : FavoriteStore.contains(entry.favoriteDraft, in: modelContext)
        }
        .fullScreenCover(isPresented: $showsFullscreenImage) {
            fullscreenImageView
        }
    }

    @ViewBuilder
    private var mediaView: some View {
        switch entry.media {
        case let .image(url, _):
            Button {
                showsFullscreenImage = true
            } label: {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        HeroCard(
                            title: String(localized: "No pudimos cargar la imagen"),
                            subtitle: String(localized: "Intenta nuevamente en unos segundos."),
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
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Abrir imagen a pantalla completa")
            .accessibilityHint("Muestra la imagen astronómica sin interfaz alrededor")
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }

        case let .video(url):
            if let embedURL = APODVideoEmbed.embedURL(for: url) {
                APODVideoPlayer(embedURL: embedURL)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    }
            } else {
                HeroCard(
                    title: String(localized: "Contenido en video"),
                    subtitle: String(localized: "Este APOD es un video. Puedes abrirlo en el navegador."),
                    symbolName: "play.rectangle.fill"
                )
            }

            Link(destination: url) {
                ActionCapsule(title: String(localized: "Abrir video"), systemImage: "arrow.up.right.square", isEmphasized: false)
            }
            .accessibilityLabel("Abrir video en el navegador")

        case .unsupported:
            HeroCard(
                title: String(localized: "Formato no soportado"),
                subtitle: String(localized: "La NASA devolvió un tipo de medio no soportado."),
                symbolName: "questionmark.video"
            )
        }
    }

    @ViewBuilder
    private var fullscreenImageView: some View {
        if case let .image(url, hdURL) = entry.media {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                AsyncImage(url: hdURL ?? url) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .failure:
                        Text("No se pudo mostrar la imagen")
                            .font(AppTypography.body)
                            .foregroundStyle(Color.white)
                    case .empty:
                        ProgressView()
                            .tint(Color.white)
                    @unknown default:
                        EmptyView()
                    }
                }

                Button {
                    showsFullscreenImage = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(AppSpacing.large)
                }
                .accessibilityLabel("Cerrar imagen a pantalla completa")
            }
        }
    }

    private func toggleFavorite() {
        if isFavorite {
            FavoriteStore.remove(entry.favoriteDraft, in: modelContext)
        } else {
            FavoriteStore.upsert(entry.favoriteDraft, in: modelContext)
        }

        isFavorite.toggle()
    }
}
