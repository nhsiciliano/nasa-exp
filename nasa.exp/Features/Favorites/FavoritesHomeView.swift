import SwiftUI
import SwiftData

struct FavoritesHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteItem.createdAt, order: .reverse) private var favorites: [FavoriteItem]

    var body: some View {
        ZStack {
            SpaceBackground()

            if favorites.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(favorites) { item in
                        NavigationLink {
                            favoriteDestination(for: item)
                        } label: {
                            FavoriteRow(item: item)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: deleteItems)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
                .accessibilityLabel("Lista de favoritos")
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .appScreenChromeSpacing()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            SectionHeader(
                title: "Archivo personal",
                subtitle: "Tus hallazgos espaciales quedan guardados como una bitacora privada de mision."
            )

            HeroCard(
                title: "Sin favoritos",
                subtitle: "Guarda APOD, Rovers o EPIC para volver rapido a tus hallazgos favoritos.",
                symbolName: "star"
            )

            HStack(spacing: AppSpacing.small) {
                InfoPill(text: "APOD")
                InfoPill(text: "Rovers")
                InfoPill(text: "EPIC")
            }
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(favorites[index])
        }

        try? modelContext.save()
    }

    @ViewBuilder
    private func favoriteDestination(for item: FavoriteItem) -> some View {
        switch item.contentType {
        case .apod:
            APODDetailView(entry: APODEntry(favoriteItem: item))
        case .rover:
            RoverPhotoDetailView(photo: RoverPhoto(favoriteItem: item))
        case .epic:
            EPICDetailView(entry: EPICEntry(favoriteItem: item))
        }
    }
}

private struct FavoriteRow: View {
    let item: FavoriteItem

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            if let mediaURL = item.mediaURL {
                AsyncImage(url: mediaURL) { phase in
                    switch phase {
                    case let .success(image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        AppColors.cardBackground
                    }
                }
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColors.cardBackground)
                    .frame(width: 74, height: 74)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(item.title)
                    .font(AppTypography.bodyStrong)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)

                Text(item.subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(1)

                Text(tag(for: item.contentType))
                    .font(AppTypography.micro)
                    .foregroundStyle(AppColors.accentMuted)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.medium)
        .background(
            LinearGradient(
                colors: [AppColors.surfaceHighlight.opacity(0.92), AppColors.surfaceBase.opacity(0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Favorito \(tag(for: item.contentType)): \(item.title). \(item.subtitle)")
        .accessibilityHint("Abre el detalle guardado")
    }

    private func tag(for type: FavoriteContentType) -> String {
        switch type {
        case .apod:
            return "APOD"
        case .rover:
            return "Rover"
        case .epic:
            return "EPIC"
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesHomeView()
            .modelContainer(for: FavoriteItem.self, inMemory: true)
    }
}
