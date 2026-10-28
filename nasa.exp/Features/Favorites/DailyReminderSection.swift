import SwiftUI
import UIKit

/// Opt-in for the daily APOD notification, shown in About.
struct DailyReminderSection: View {
    @State private var viewModel = DailyReminderViewModel()
    @Environment(\.openURL) private var openURL

    var body: some View {
        SurfacePanel {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                InfoPill(text: String(localized: "NOTIFICACIÓN DIARIA"))

                Toggle(isOn: isEnabled) {
                    Text("Avisarme con la foto del día")
                        .font(AppTypography.bodyStrong)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.accent)

                if viewModel.settings.isEnabled {
                    DatePicker(selection: time, displayedComponents: .hourAndMinute) {
                        Text("Hora del aviso")
                            .font(AppTypography.body)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .tint(AppColors.accent)
                }

                Text("La foto nueva sale todos los días a partir de las \(publicationTime), en tu hora.")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textSecondary)

                if viewModel.isPermissionDenied {
                    Text("Las notificaciones de NASA Exp están desactivadas. Podés activarlas en Ajustes.")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textPrimary)

                    Button {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    } label: {
                        ActionCapsule(title: String(localized: "Abrir Ajustes"), systemImage: "gear", isEmphasized: false)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await viewModel.checkPermission()
        }
    }

    private var isEnabled: Binding<Bool> {
        Binding {
            viewModel.settings.isEnabled
        } set: { isEnabled in
            Task { await viewModel.setEnabled(isEnabled) }
        }
    }

    private var time: Binding<Date> {
        Binding {
            viewModel.time()
        } set: { time in
            Task { await viewModel.setTime(time) }
        }
    }

    /// When the new entry is out, in the device's time zone (00:15 in New York).
    private var publicationTime: String {
        APODPublicationSchedule.nextPublication(after: .now).formatted(date: .omitted, time: .shortened)
    }
}
