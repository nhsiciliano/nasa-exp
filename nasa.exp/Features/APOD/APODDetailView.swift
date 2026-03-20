import SwiftUI
import SwiftData

struct APODDetailView: View {
    let entry: APODEntry

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
                        InfoPill(text: "DEEP SPACE")
                        InfoPill(text: "EDITORIAL")
                    }

                    mediaView

                    HStack(spacing: AppSpacing.small) {
                        InfoPill(text: "APOD")
                        if entry.copyright != nil {
                            InfoPill(text: "Con creditos")
                        }
                    }

                    if let copyright = entry.copyright, !copyright.isEmpty {
                        Text("Credito: \(copyright)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Text(entry.explanation)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .accessibilityLabel("Descripcion completa. \(entry.explanation)")

                    if let shareURL = entry.shareURL {
                        ShareLink(item: shareURL) {
                            ActionCapsule(title: "Compartir APOD", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Compartir APOD")
                    }

                    Button {
                        toggleFavorite()
                    } label: {
                        ActionCapsule(
                            title: isFavorite ? "Quitar de favoritos" : "Guardar en favoritos",
                            systemImage: isFavorite ? "star.slash.fill" : "star.fill",
                            isEmphasized: false
                        )
                    }
                    .accessibilityHint(isFavorite ? "Elimina este contenido de tu archivo personal" : "Guarda este contenido en tu archivo personal")
                }
                .padding(AppSpacing.large)
            }
        }
        .navigationTitle("Detalle APOD")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorite = FavoriteStore.contains(entry.favoriteDraft, in: modelContext)
        }
        .fullScreenCover(isPresented: $showsFullscreenImage) {
            fullscreenImageView
        }
    }

    @ViewBuilder
    private var mediaView: some View {
        switch entry.media {
        case let .image(url):
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
                            title: "No pudimos cargar la imagen",
                            subtitle: "Intenta nuevamente en unos segundos.",
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
            .accessibilityHint("Muestra la imagen astronomica sin interfaz alrededor")
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }

        case let .video(url):
            HeroCard(
                title: "Contenido en video",
                subtitle: "Este APOD es un video. Puedes abrirlo en el navegador.",
                symbolName: "play.rectangle.fill"
            )

            Link(destination: url) {
                ActionCapsule(title: "Abrir video", systemImage: "arrow.up.right.square", isEmphasized: false)
            }
            .accessibilityLabel("Abrir video en el navegador")

        case .unsupported:
            HeroCard(
                title: "Formato no soportado",
                subtitle: "La NASA devolvio un tipo de medio no soportado.",
                symbolName: "questionmark.video"
            )
        }
    }

    @ViewBuilder
    private var fullscreenImageView: some View {
        if case let .image(url) = entry.media {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                AsyncImage(url: url) { phase in
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
            FavoriteStore.add(entry.favoriteDraft, in: modelContext)
        }

        isFavorite.toggle()
    }
}
