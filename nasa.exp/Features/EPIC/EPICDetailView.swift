import SwiftUI
import SwiftData

struct EPICDetailView: View {
    let entry: EPICEntry

    @Environment(\.modelContext) private var modelContext
    @State private var isFavorite = false

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    AsyncImage(url: entry.imageURL) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                        case .failure:
                            HeroCard(
                                title: "No se pudo cargar la imagen",
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
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    }

                    SectionHeader(title: entry.title, subtitle: entry.displayDate)

                    HStack(spacing: AppSpacing.small) {
                        InfoPill(text: "EPIC")
                        InfoPill(text: "ORBITAL")
                    }

                    Text(entry.caption)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)
                        .accessibilityLabel("Descripción de la imagen. \(entry.caption)")

                    InfoPill(text: entry.coordinateSummary)

                    if let shareURL = entry.imageURL {
                        ShareLink(item: shareURL) {
                            ActionCapsule(title: "Compartir imagen", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Compartir imagen EPIC")
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
                    .accessibilityHint(isFavorite ? "Elimina esta imagen de tus favoritos" : "Guarda esta imagen en tus favoritos")
                }
                .padding(AppSpacing.large)
            }
        }
        .navigationTitle("Detalle EPIC")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isFavorite = FavoriteStore.contains(entry.favoriteDraft, in: modelContext)
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
