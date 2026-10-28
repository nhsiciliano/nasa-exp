import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Source: Identifiable {
        let title: String
        let host: String
        let url: URL

        var id: URL { url }
    }

    private let sources = [
        Source(
            title: String(localized: "Imagen astronómica del día"),
            host: "science.nasa.gov/apod",
            url: URL(string: "https://science.nasa.gov/apod")!
        ),
        Source(
            title: String(localized: "Fotos crudas de los rovers"),
            host: "mars.nasa.gov",
            url: URL(string: "https://mars.nasa.gov")!
        ),
        Source(
            title: String(localized: "Cámara EPIC de la Tierra"),
            host: "epic.gsfc.nasa.gov",
            url: URL(string: "https://epic.gsfc.nasa.gov")!
        ),
    ]

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "–"
        let build = info?["CFBundleVersion"] as? String ?? "–"
        return String(localized: "Versión \(version) (\(build))")
    }

    var body: some View {
        ZStack {
            SpaceBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        SectionHeader(title: "NASA Exp", subtitle: versionText)

                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppColors.textSecondary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .accessibilityLabel("Cerrar")
                    }

                    SurfacePanel {
                        VStack(alignment: .leading, spacing: AppSpacing.small) {
                            InfoPill(text: String(localized: "AVISO"))

                            Text("NASA Exp no es una app oficial de la NASA ni está afiliada a ella. Las imágenes y datos provienen de servicios públicos de la NASA (science.nasa.gov, mars.nasa.gov, api.nasa.gov) y conservan sus créditos originales.")
                                .font(AppTypography.body)
                                .foregroundStyle(AppColors.textPrimary)
                                .lineSpacing(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    DailyReminderSection()

                    SurfacePanel {
                        VStack(alignment: .leading, spacing: AppSpacing.medium) {
                            InfoPill(text: String(localized: "FUENTES"))

                            ForEach(sources) { source in
                                Link(destination: source.url) {
                                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                        Text(source.title)
                                            .font(AppTypography.bodyStrong)
                                            .foregroundStyle(AppColors.textPrimary)

                                        Text(source.host)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColors.accentMuted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .accessibilityHint("Abre el sitio en el navegador")
                            }
                        }
                    }
                }
                .padding(AppSpacing.large)
            }
        }
    }
}

#Preview {
    AboutView()
}
