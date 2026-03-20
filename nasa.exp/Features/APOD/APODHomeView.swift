import SwiftUI

@MainActor
struct APODHomeView: View {
    @StateObject private var viewModel = APODViewModel()

    var body: some View {
        ZStack {
            SpaceBackground()

            content
        }
        .toolbar(.hidden, for: .navigationBar)
        .appScreenChromeSpacing()
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            loadingView
        case let .loaded(entry):
            loadedView(entry)
        case let .failed(message):
            errorView(message)
        }
    }

    private var loadingView: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .tint(AppColors.accent)
            Text("Cargando APOD...")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Text("Estamos consultando la portada astronomica del dia.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cargando la imagen astronomica del dia")
    }

    private func loadedView(_ entry: APODEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                SectionHeader(
                    title: "Hoy en NASA",
                    subtitle: entry.displayDate
                )

                HeroCard(
                    title: entry.title,
                    subtitle: "Portada orbital del dia con media inmersiva, contexto editorial y acceso directo al detalle.",
                    symbolName: "sparkles.tv"
                )

                mediaView(for: entry)

                HStack(spacing: AppSpacing.small) {
                    InfoPill(text: "APOD")
                    InfoPill(text: "Diario")
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
                    .lineLimit(4)
                    .textSelection(.enabled)
                    .accessibilityLabel("Resumen de hoy en NASA. \(entry.explanation)")

                NavigationLink {
                    APODDetailView(entry: entry)
                } label: {
                    ActionCapsule(
                        title: "Ver detalle completo",
                        systemImage: "arrow.right.circle.fill",
                        isEmphasized: false
                    )
                }

                if let shareURL = entry.shareURL {
                    ShareLink(item: shareURL) {
                        ActionCapsule(title: "Compartir", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Compartir la imagen astronomica del dia")
                }
            }
            .padding(AppSpacing.large)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder
    private func mediaView(for entry: APODEntry) -> some View {
        switch entry.media {
        case let .image(url):
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .overlay(alignment: .topLeading) {
                            InfoPill(text: "IMAGEN HD")
                                .padding(AppSpacing.medium)
                        }
                        .accessibilityLabel("Imagen astronomica del dia")
                        .accessibilityHint("Desliza hacia abajo para refrescar o abre el detalle para mas contexto")
                case .failure:
                    HeroCard(
                        title: "No pudimos cargar la imagen",
                        subtitle: "Toca refrescar para intentar nuevamente.",
                        symbolName: "photo.badge.exclamationmark"
                    )
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppColors.cardBackground)
                        ProgressView()
                            .tint(AppColors.accent)
                    }
                    .frame(height: 280)
                @unknown default:
                    EmptyView()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            }

        case let .video(url):
            HeroCard(
                title: "Contenido en video",
                subtitle: "Este APOD es un video. Abre el enlace para verlo.",
                symbolName: "play.rectangle.fill"
            )

            Link(destination: url) {
                ActionCapsule(title: "Abrir video", systemImage: "arrow.up.right.square", isEmphasized: false)
            }
            .accessibilityLabel("Abrir video del dia en el navegador")

        case .unsupported:
            HeroCard(
                title: "Formato no soportado",
                subtitle: "La NASA devolvio un tipo de medio que no soportamos todavia.",
                symbolName: "questionmark.video"
            )
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HeroCard(
                title: "No pudimos cargar la portada de hoy",
                subtitle: "\(message) Reintenta en unos segundos o revisa tu conexion.",
                symbolName: "exclamationmark.triangle.fill"
            )

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                ActionCapsule(title: "Reintentar", systemImage: "arrow.clockwise")
            }
            .accessibilityHint("Vuelve a consultar la portada astronomica del dia")
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    NavigationStack {
        APODHomeView()
    }
}
