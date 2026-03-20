import SwiftUI

@MainActor
struct RoversHomeView: View {
    @StateObject private var viewModel = RoversViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: AppSpacing.medium),
        GridItem(.flexible(), spacing: AppSpacing.medium),
    ]

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    header
                    filters
                    results
                }
                .padding(AppSpacing.large)
            }
            .refreshable {
                await viewModel.search()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .appScreenChromeSpacing()
        .task {
            await viewModel.loadIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            SectionHeader(
                title: "Rovers de Marte",
                subtitle: "Filtra por rover, camara y fecha para explorar fotos reales de NASA."
            )

            HeroCard(
                title: "Superficie roja, telemetria real",
                subtitle: "Una grilla de exploracion inspirada en terminales de mision para navegar imagenes de Curiosity, Spirit, Opportunity y Perseverance.",
                symbolName: "antenna.radiowaves.left.and.right"
            )
        }
    }

    private var filters: some View {
        SurfacePanel {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.small) {
                    InfoPill(text: "ROVER")
                    InfoPill(text: "CAMARA")
                    InfoPill(text: "EARTH DATE")
                }

            Picker("Rover", selection: $viewModel.selectedRover) {
                ForEach(RoverName.allCases) { rover in
                    Text(rover.title).tag(rover)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Seleccionar rover")

            DatePicker("Fecha en Tierra", selection: $viewModel.selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)
                .environment(\.timeZone, TimeZone(secondsFromGMT: 0) ?? .current)
                .onChange(of: viewModel.selectedDate) { _, newValue in
                    if newValue > viewModel.maxSelectableDate {
                        viewModel.selectedDate = viewModel.maxSelectableDate
                    }
                }
                .accessibilityLabel("Seleccionar fecha en Tierra")

            Picker("Camara", selection: $viewModel.selectedCamera) {
                ForEach(viewModel.availableCameras) { camera in
                    Text(camera.title).tag(camera)
                }
            }
            .accessibilityLabel("Seleccionar camara")

            Button {
                Task {
                    await viewModel.search()
                }
            } label: {
                ActionCapsule(title: viewModel.isSearching ? "Buscando..." : "Buscar fotos", systemImage: "magnifyingglass")
            }
            .disabled(viewModel.isSearching)
            .accessibilityHint("Busca imagenes del rover con los filtros actuales")
        }
        }
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Cargando fotos...")
                .font(AppTypography.body)
                .tint(AppColors.accent)
                .frame(maxWidth: .infinity, alignment: .center)

        case let .loaded(photos):
            if photos.isEmpty {
                HeroCard(
                    title: "Sin resultados para esta consulta",
                    subtitle: "No encontramos fotos para \(viewModel.selectedRover.title) con esos filtros. Prueba con otra fecha, rover o camara.",
                    symbolName: "camera.metering.none"
                )
            } else {
                LazyVGrid(columns: columns, spacing: AppSpacing.medium) {
                    ForEach(photos) { photo in
                        NavigationLink {
                            RoverPhotoDetailView(photo: photo)
                        } label: {
                            RoverPhotoCard(photo: photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

        case let .failed(message):
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HeroCard(
                    title: "No se pudieron cargar las fotos",
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
                .accessibilityHint("Vuelve a consultar la galeria del rover")
            }
        }
    }
}

private struct RoverPhotoCard: View {
    let photo: RoverPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AsyncImage(url: photo.imageURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    ZStack {
                        AppColors.cardBackground
                        Image(systemName: "photo")
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

            Text(photo.roverName)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)

            Text(photo.cameraName)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.accentMuted)

            Text(photo.displayDate)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
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
        .accessibilityLabel("Foto de \(photo.roverName), camara \(photo.cameraName), fecha \(photo.displayDate)")
        .accessibilityHint("Abre el detalle de la foto")
    }
}

#Preview {
    NavigationStack {
        RoversHomeView()
    }
}
