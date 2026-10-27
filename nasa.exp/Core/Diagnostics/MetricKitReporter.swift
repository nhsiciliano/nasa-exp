import Foundation
import MetricKit
import OSLog

/// Subscribes to MetricKit and keeps every diagnostic payload (crashes, hangs, CPU and disk
/// exceptions) as JSON in Application Support. Nothing is sent off the device.
nonisolated final class MetricKitReporter: NSObject, MXMetricManagerSubscriber, @unchecked Sendable {
    static let shared = MetricKitReporter()

    static var defaultDirectoryURL: URL {
        URL.applicationSupportDirectory.appending(path: "Diagnostics", directoryHint: .isDirectory)
    }

    private let directoryURL: URL
    private let logger = Logger(subsystem: "den-mobile.nasaexp", category: "MetricKit")

    init(directoryURL: URL = MetricKitReporter.defaultDirectoryURL) {
        self.directoryURL = directoryURL
        super.init()
    }

    func start() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            store(jsonRepresentation: payload.jsonRepresentation())
        }
    }

    @discardableResult
    func store(jsonRepresentation: Data, receivedAt date: Date = .now) -> URL? {
        let timestamp = Int(date.timeIntervalSince1970)
        let fileURL = directoryURL.appending(path: "diagnostic-\(timestamp)-\(UUID().uuidString).json")

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try jsonRepresentation.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            logger.error("Could not store diagnostic payload: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }
}
