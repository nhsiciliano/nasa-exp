import SwiftUI
import UIKit

/// "Guardar en Fotos" action: saves the image with its credit and confirms inline,
/// or explains the failure in an alert (with a shortcut to Settings when access was denied).
struct SaveToPhotosButton: View {
    let item: PhotoSaveItem

    @Environment(\.openURL) private var openURL
    @State private var saveState: SaveState = .idle
    @State private var failure: PhotoSaveFailure?

    private enum SaveState {
        case idle
        case saving
        case saved
    }

    var body: some View {
        Button {
            Task {
                await save()
            }
        } label: {
            ActionCapsule(title: title, systemImage: systemImage, isEmphasized: false)
        }
        .disabled(saveState != .idle)
        .accessibilityHint("Guarda la imagen en tu fototeca con su título y crédito")
        .alert(
            "No se pudo guardar",
            isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } }),
            presenting: failure
        ) { failure in
            if failure.isAccessDenied {
                Button("Abrir Ajustes") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        openURL(settingsURL)
                    }
                }
            }
            Button("OK", role: .cancel) {}
        } message: { failure in
            Text(failure.message)
        }
        .onChange(of: item) {
            saveState = .idle
        }
    }

    private var title: String {
        switch saveState {
        case .idle:
            return "Guardar en Fotos"
        case .saving:
            return "Guardando..."
        case .saved:
            return "Guardada en Fotos"
        }
    }

    private var systemImage: String {
        switch saveState {
        case .idle:
            return "square.and.arrow.down"
        case .saving:
            return "hourglass"
        case .saved:
            return "checkmark.circle.fill"
        }
    }

    private func save() async {
        saveState = .saving

        do {
            try await PhotoLibrarySaver.save(item)
            saveState = .saved
            AccessibilityNotification.Announcement("Imagen guardada en Fotos").post()
        } catch {
            saveState = .idle
            failure = PhotoSaveFailure(error: error)
        }
    }
}

private struct PhotoSaveFailure {
    let message: String
    let isAccessDenied: Bool

    init(error: Error) {
        message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if case .accessDenied = error as? PhotoLibrarySaveError {
            isAccessDenied = true
        } else {
            isAccessDenied = false
        }
    }
}
