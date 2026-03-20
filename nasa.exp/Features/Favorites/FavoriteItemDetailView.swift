import SwiftUI

struct FavoriteItemDetailView: View {
    let item: FavoriteItem

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    if let mediaURL = item.mediaURL {
                        AsyncImage(url: mediaURL) { phase in
                            switch phase {
                            case let .success(image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                HeroCard(
                                    title: "No se pudo cargar la imagen",
                                    subtitle: "El recurso ya no esta disponible.",
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

                    SectionHeader(title: item.title, subtitle: item.subtitle)

                    InfoPill(text: "ARCHIVE ENTRY")

                    Text(item.details)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColors.textPrimary)

                    if let mediaURL = item.mediaURL {
                        ShareLink(item: mediaURL) {
                            ActionCapsule(title: "Compartir", systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .padding(AppSpacing.large)
            }
        }
        .navigationTitle("Favorito")
        .navigationBarTitleDisplayMode(.inline)
    }
}
