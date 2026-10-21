import SwiftUI
import SwiftData

struct FavoritesHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FavoriteItem.createdAt, order: .reverse) private var favorites: [FavoriteItem]
    @State private var filter: FavoritesFilter = .all
    @State private var isShowingAbout = false

    private var visibleFavorites: [FavoriteItem] {
        guard let contentType = filter.contentType else {
            return favorites
        }

        return favorites.filter { $0.contentType == contentType }
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            if favorites.isEmpty {
                emptyState
            } else {
                VStack(spacing: AppSpacing.medium) {
                    HStack(spacing: AppSpacing.small) {
                        filterPicker
                        aboutButton
                    }
                    .padding(.horizontal, AppSpacing.large)

                    if visibleFavorites.isEmpty {
                        emptyFilterState
                    } else {
                        favoritesList
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .appScreenChromeSpacing()
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
        }
    }

    private var aboutButton: some View {
        Button {
            isShowingAbout = true
        } label: {
            Image(systemName: "info.circle")
                .font(.title3)
                .foregroundStyle(AppColors.accent)
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Acerca de NASA Exp")
    }

    private var filterPicker: some View {
        Picker("Tipo de favorito", selection: $filter) {
            ForEach(FavoritesFilter.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Filtrar favoritos por tipo")
    }

    private var favoritesList: some View {
        List {
            ForEach(visibleFavorites) { item in
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

    private var emptyFilterState: some View {
        HeroCard(
            title: String(localized: "Sin favoritos de \(filter.title)"),
            subtitle: String(localized: "Los que guardes desde el detalle van a aparecer acá."),
            symbolName: "line.3.horizontal.decrease.circle"
        )
        .padding(.horizontal, AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                SectionHeader(
                    title: String(localized: "Archivo personal"),
                    subtitle: String(localized: "Tus hallazgos espaciales quedan guardados como una bitácora privada de misión.")
                )
                aboutButton
            }

            HeroCard(
                title: String(localized: "Sin favoritos"),
                subtitle: String(localized: "Guarda APOD, Rovers o EPIC para volver rápido a tus hallazgos favoritos."),
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
        let items = visibleFavorites
        for index in offsets {
            modelContext.delete(items[index])
        }

        try? modelContext.save()
    }

    @ViewBuilder
    private func favoriteDestination(for item: FavoriteItem) -> some View {
        switch item.contentType {
        case .apod:
            APODDetailView(entry: APODEntry(favoriteItem: item), refreshesStoredFavorite: false)
        case .rover:
            RoverPhotoDetailView(photo: RoverPhoto(favoriteItem: item), refreshesStoredFavorite: false)
        case .epic:
            EPICDetailView(entry: EPICEntry(favoriteItem: item), refreshesStoredFavorite: false)
        }
    }
}

private enum FavoritesFilter: String, CaseIterable, Identifiable {
    case all
    case apod
    case rover
    case epic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return String(localized: "Todos")
        case .apod:
            return "APOD"
        case .rover:
            return "Rovers"
        case .epic:
            return "EPIC"
        }
    }

    var contentType: FavoriteContentType? {
        switch self {
        case .all:
            return nil
        case .apod:
            return .apod
        case .rover:
            return .rover
        case .epic:
            return .epic
        }
    }
}

private struct FavoriteRow: View {
    let item: FavoriteItem

    private var displayDate: String {
        item.displayDate()
    }

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            if let previewURL = item.thumbnailURL ?? item.mediaURL {
                AsyncImage(url: previewURL) { phase in
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

                Text(displayDate)
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
        .accessibilityLabel("Favorito \(tag(for: item.contentType)): \(item.title). \(displayDate)")
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
