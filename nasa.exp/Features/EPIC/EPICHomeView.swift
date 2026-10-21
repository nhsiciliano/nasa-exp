import SwiftUI

@MainActor
struct EPICHomeView: View {
    @StateObject private var viewModel = EPICViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.medium),
        GridItem(.flexible(), spacing: AppSpacing.medium),
    ]

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    SectionHeader(
                        title: "La Tierra desde EPIC",
                        subtitle: "Selecciona una fecha para explorar imágenes del planeta en el observatorio EPIC."
                    )

                    HeroCard(
                        title: "Ventana orbital a la Tierra",
                        subtitle: "Una lectura visual del planeta con coordenadas, fecha y composición para sentir la escala de la observación en tiempo real.",
                        symbolName: "globe.americas.fill"
                    )

                    filters
                    results
                }
                .padding(AppSpacing.large)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .appScreenChromeSpacing()
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var filters: some View {
        SurfacePanel {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.small) {
                    InfoPill(text: "EPIC")
                    InfoPill(text: "TIMELINE")
                    InfoPill(text: "EARTH VIEW")
                }

            DatePicker("Fecha", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0) ?? .current)
                .onChange(of: viewModel.selectedDate) { _, newValue in
                    if newValue > viewModel.maxSelectableDate {
                        viewModel.selectedDate = viewModel.maxSelectableDate
                    }
                }
                .accessibilityLabel("Seleccionar fecha EPIC")

            Button {
                Task {
                    await viewModel.search()
                }
            } label: {
                ActionCapsule(title: viewModel.isSearching ? "Buscando..." : "Buscar imágenes", systemImage: "globe.americas.fill")
            }
            .disabled(viewModel.isSearching)
            .accessibilityHint("Busca imágenes de la Tierra para la fecha seleccionada")
        }
        }
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Cargando EPIC...")
                .font(AppTypography.body)
                .tint(AppColors.accent)
                .frame(maxWidth: .infinity, alignment: .center)

        case let .loaded(entries):
            if entries.isEmpty {
                HeroCard(
                    title: "Sin imágenes para esta fecha",
                    subtitle: "No encontramos imágenes EPIC para la fecha seleccionada. Prueba con otro día cercano.",
                    symbolName: "globe.badge.chevron.backward"
                )
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.medium) {
                    ForEach(entries) { entry in
                        NavigationLink {
                            EPICDetailView(entry: entry)
                        } label: {
                            EPICCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

        case let .failed(message):
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HeroCard(
                    title: "No se pudieron cargar las imágenes",
                    subtitle: message,
                    symbolName: "exclamationmark.triangle.fill"
                )

                Button {
                    Task {
                        await viewModel.search()
                    }
                } label: {
                    ActionCapsule(title: "Reintentar", systemImage: "arrow.clockwise")
                }
                .accessibilityHint("Vuelve a consultar el archivo EPIC")
            }
        }
    }
}

private struct EPICCard: View {
    let entry: EPICEntry

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AsyncImage(url: entry.thumbnailURL ?? entry.imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    ZStack {
                        AppColors.cardBackground
                        Image(systemName: "globe")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tint(AppColors.accent)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(entry.displayDate)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)

            Text(entry.coordinateSummary)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.accentMuted)
                .lineLimit(1)
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
        .accessibilityLabel("Imagen EPIC del \(entry.displayDate), coordenadas \(entry.coordinateSummary)")
        .accessibilityHint("Abre el detalle de la imagen")
    }
}

#Preview {
    NavigationStack {
        EPICHomeView()
    }
}
