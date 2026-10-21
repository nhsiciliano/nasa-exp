import SwiftUI

@MainActor
struct RoversHomeView: View {
    @StateObject private var viewModel = RoversViewModel()
    @FocusState private var isSolFieldFocused: Bool

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
                await viewModel.refresh()
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .appScreenChromeSpacing()
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.selectedRover) { _, _ in
            Task {
                await viewModel.roverSelectionChanged()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            SectionHeader(
                title: "Rovers de Marte",
                subtitle: "Explorá las imágenes crudas que Curiosity y Perseverance envían desde la superficie, sol a sol."
            )

            HeroCard(
                title: viewModel.selectedRover.title,
                subtitle: "\(viewModel.selectedRover.missionName). \(viewModel.selectedRover.landingSummary). Feed directo de mars.nasa.gov.",
                symbolName: "antenna.radiowaves.left.and.right"
            )
        }
    }

    private var filters: some View {
        SurfacePanel {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.small) {
                    InfoPill(text: "ROVER")
                    InfoPill(text: "SOL")
                    InfoPill(text: "CÁMARA")
                }

                Picker("Rover", selection: $viewModel.selectedRover) {
                    ForEach(RoverName.allCases) { rover in
                        Text(rover.title).tag(rover)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel("Seleccionar rover")

                solControls

                Picker("Cámara", selection: $viewModel.selectedCamera) {
                    ForEach(viewModel.availableCameras) { camera in
                        Text(camera.title).tag(camera)
                    }
                }
                .accessibilityLabel("Seleccionar cámara")

                Button {
                    isSolFieldFocused = false
                    Task {
                        await viewModel.search()
                    }
                } label: {
                    ActionCapsule(
                        title: viewModel.isSearching ? "Buscando..." : "Buscar fotos",
                        systemImage: "magnifyingglass"
                    )
                }
                .disabled(viewModel.isSearching)
                .accessibilityHint("Busca imágenes del rover con los filtros actuales")
            }
        }
    }

    private var solControls: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.medium) {
                solStepButton(systemImage: "minus.circle.fill", label: "Sol anterior", isEnabled: viewModel.canStepBackward) {
                    await viewModel.stepSol(by: -1)
                }

                TextField("Sol", value: $viewModel.sol, format: .number.grouping(.never))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(AppTypography.title3)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(.vertical, AppSpacing.small)
                    .background(AppColors.surfaceBase.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(AppColors.border, lineWidth: 1)
                    }
                    .focused($isSolFieldFocused)
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }
                    .accessibilityLabel("Sol marciano")
                    .accessibilityHint("Escribe el número de sol y busca")

                solStepButton(systemImage: "plus.circle.fill", label: "Sol siguiente", isEnabled: viewModel.canStepForward) {
                    await viewModel.stepSol(by: 1)
                }
            }

            HStack {
                if let latestSol = viewModel.latestSol {
                    Text("Sol más reciente: \(latestSol, format: .number.grouping(.never))")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }

                Spacer(minLength: 0)

                Button {
                    isSolFieldFocused = false
                    Task {
                        await viewModel.jumpToLatestSol()
                    }
                } label: {
                    Label("Último sol", systemImage: "clock.arrow.circlepath")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.accent)
                }
                .disabled(viewModel.isSearching)
                .accessibilityHint("Salta al sol más reciente disponible para este rover")
            }
        }
    }

    private func solStepButton(
        systemImage: String,
        label: String,
        isEnabled: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            isSolFieldFocused = false
            Task {
                await action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(isEnabled ? AppColors.accent : AppColors.textTertiary)
                .frame(width: 44, height: 44)
        }
        .disabled(!isEnabled || viewModel.isSearching)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Cargando fotos...")
                .font(AppTypography.body)
                .tint(AppColors.accent)
                .frame(maxWidth: .infinity, alignment: .center)

        case let .loaded(feed):
            if feed.photos.isEmpty {
                HeroCard(
                    title: "Sin fotos en el sol \(viewModel.sol)",
                    subtitle: "\(viewModel.selectedRover.title) no envió imágenes con esos filtros. Probá con otro sol o cámara.",
                    symbolName: "camera.metering.none"
                )
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    HStack(spacing: AppSpacing.small) {
                        InfoPill(text: "SOL \(viewModel.sol)")
                        InfoPill(text: "\(feed.photos.count) DE \(feed.total)")
                    }

                    LazyVGrid(columns: columns, spacing: AppSpacing.medium) {
                        ForEach(feed.photos) { photo in
                            NavigationLink {
                                RoverPhotoDetailView(photo: photo)
                            } label: {
                                RoverPhotoCard(photo: photo)
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("rovers.photoCard")
                            .onAppear {
                                guard photo.id == feed.photos.last?.id else {
                                    return
                                }
                                Task {
                                    await viewModel.loadMoreIfNeeded(after: photo)
                                }
                            }
                        }
                    }

                    loadMoreSection(feed)
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
                .accessibilityHint("Vuelve a consultar la galería del rover")
                .accessibilityIdentifier("rovers.retry")
            }
        }
    }

    @ViewBuilder
    private func loadMoreSection(_ feed: RoversViewModel.Feed) -> some View {
        if let message = viewModel.loadMoreErrorMessage {
            Text(message)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.accentSecondary)
        }

        if feed.hasMore {
            Button {
                Task {
                    await viewModel.loadMore()
                }
            } label: {
                ActionCapsule(
                    title: viewModel.isLoadingMore ? "Cargando..." : "Cargar más fotos",
                    systemImage: "arrow.down.circle",
                    isEmphasized: false
                )
            }
            .disabled(viewModel.isLoadingMore)
            .accessibilityHint("Carga la siguiente página de fotos de este sol")
        }
    }
}

private struct RoverPhotoCard: View {
    let photo: RoverPhoto

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            AsyncImage(url: photo.thumbnailURL) { phase in
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

            Text(photo.cameraName)
                .font(AppTypography.bodyStrong)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)

            Text(photo.solLabel)
                .font(AppTypography.micro)
                .foregroundStyle(AppColors.accentMuted)

            Text(photo.displayDate)
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textSecondary)
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
        .accessibilityLabel("Foto de \(photo.roverName), cámara \(photo.cameraName), \(photo.displayDate)")
        .accessibilityHint("Abre el detalle de la foto")
    }
}

#Preview {
    NavigationStack {
        RoversHomeView()
    }
}
