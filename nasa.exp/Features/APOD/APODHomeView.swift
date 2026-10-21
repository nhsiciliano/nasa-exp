import SwiftUI

@MainActor
struct APODHomeView: View {
    @StateObject private var viewModel = APODViewModel()

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    SectionHeader(
                        title: viewModel.isShowingLatest ? "Hoy en NASA" : "APOD",
                        subtitle: headerSubtitle
                    )

                    dateControls

                    content
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

    private var headerSubtitle: String {
        switch viewModel.state {
        case .idle, .loading:
            return "Sintonizando el archivo de NASA..."
        case let .loaded(entry):
            return entry.displayDate
        case .failed:
            return "Sin señal para esta fecha."
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

    // MARK: - Date navigation

    private var dateControls: some View {
        SurfacePanel {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.small) {
                    dayStepper
                    Spacer(minLength: 0)
                    randomDateButton(showsTitle: true)
                }

                HStack(spacing: AppSpacing.small) {
                    dayStepper
                    Spacer(minLength: 0)
                    randomDateButton(showsTitle: false)
                }

                VStack(spacing: AppSpacing.medium) {
                    dayStepper
                    randomDateButton(showsTitle: true)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var dayStepper: some View {
        HStack(spacing: AppSpacing.small) {
            stepButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Día anterior",
                isEnabled: viewModel.canGoToPreviousDay
            ) {
                await viewModel.goToPreviousDay()
            }

            DatePicker(
                "Fecha del APOD",
                selection: selectedDateBinding,
                in: viewModel.selectableDates,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.accent)
            .environment(\.colorScheme, .dark)
            .accessibilityLabel("Fecha del APOD")

            stepButton(
                systemImage: "chevron.right",
                accessibilityLabel: "Día siguiente",
                isEnabled: viewModel.canGoToNextDay
            ) {
                await viewModel.goToNextDay()
            }
        }
    }

    private func randomDateButton(showsTitle: Bool) -> some View {
        Button {
            Task {
                await viewModel.goToRandomDate()
            }
        } label: {
            Group {
                if showsTitle {
                    Label("Aleatorio", systemImage: "dice.fill")
                } else {
                    Image(systemName: "dice.fill")
                }
            }
            .font(AppTypography.bodyStrong)
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, showsTitle ? AppSpacing.medium : 0)
            .frame(minWidth: 44, minHeight: 44)
            .background(AppColors.accentSecondary.opacity(0.24))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(AppColors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Fecha aleatoria")
        .accessibilityHint("Carga la imagen astronómica de un día al azar desde 1995")
    }

    private func stepButton(
        systemImage: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task {
                await action()
            }
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 44, height: 44)
                .background(AppColors.surfaceHighlight)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(AppColors.border, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(accessibilityLabel)
    }

    private var selectedDateBinding: Binding<Date> {
        Binding {
            viewModel.selectedDate
        } set: { newDate in
            guard !Calendar.current.isDate(newDate, inSameDayAs: viewModel.selectedDate) else {
                return
            }

            Task {
                await viewModel.load(date: newDate)
            }
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: AppSpacing.medium) {
            ProgressView()
                .tint(AppColors.accent)
            Text("Cargando APOD...")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textSecondary)
            Text("Estamos consultando el archivo astronómico de NASA.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cargando la imagen astronómica")
    }

    @ViewBuilder
    private func loadedView(_ entry: APODEntry) -> some View {
        HeroCard(
            title: entry.title,
            subtitle: "Portada orbital del día con media inmersiva, contexto editorial y acceso directo al detalle.",
            symbolName: "sparkles.tv"
        )

        mediaView(for: entry)

        HStack(spacing: AppSpacing.small) {
            InfoPill(text: "APOD")
            InfoPill(text: "Diario")
            if entry.copyright != nil {
                InfoPill(text: "Con créditos")
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
            .lineLimit(4)
            .textSelection(.enabled)
            .accessibilityLabel("Resumen del APOD. \(entry.explanation)")

        NavigationLink {
            APODDetailView(entry: entry)
        } label: {
            ActionCapsule(
                title: "Ver detalle completo",
                systemImage: "arrow.right.circle.fill",
                isEmphasized: false
            )
        }

        APODShareButton(
            entry: entry,
            title: "Compartir",
            accessibilityLabel: "Compartir la imagen astronómica"
        )
    }

    @ViewBuilder
    private func mediaView(for entry: APODEntry) -> some View {
        switch entry.media {
        case let .image(url, _):
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFit()
                        .overlay(alignment: .topLeading) {
                            InfoPill(text: "IMAGEN")
                                .padding(AppSpacing.medium)
                        }
                        .accessibilityLabel("Imagen astronómica del día")
                        .accessibilityHint("Desliza hacia abajo para refrescar o abre el detalle para más contexto")
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
            .accessibilityLabel("Abrir video del día en el navegador")

        case .unsupported:
            HeroCard(
                title: "Formato no soportado",
                subtitle: "La NASA devolvió un tipo de medio que no soportamos todavía.",
                symbolName: "questionmark.video"
            )
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            HeroCard(
                title: viewModel.isShowingLatest ? "No pudimos cargar la portada de hoy" : "No pudimos cargar esta fecha",
                subtitle: message,
                symbolName: "exclamationmark.triangle.fill"
            )

            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                ActionCapsule(title: "Reintentar", systemImage: "arrow.clockwise")
            }
            .accessibilityHint("Vuelve a consultar la imagen astronómica de la fecha elegida")
        }
    }
}

#Preview {
    NavigationStack {
        APODHomeView()
    }
}
