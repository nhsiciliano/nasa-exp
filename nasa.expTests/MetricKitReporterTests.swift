import Foundation
import XCTest
@testable import nasa_exp

final class MetricKitReporterTests: XCTestCase {
    func test_storeJSONRepresentation_writesPayloadToDirectory() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appending(path: "MetricKitReporterTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let reporter = MetricKitReporter(directoryURL: directoryURL)
        let payload = Data(#"{"crashDiagnostics":[]}"#.utf8)

        let fileURL = try XCTUnwrap(reporter.store(jsonRepresentation: payload, receivedAt: Date(timeIntervalSince1970: 1_700_000_000)))

        XCTAssertEqual(fileURL.deletingLastPathComponent().standardizedFileURL, directoryURL.standardizedFileURL)
        XCTAssertTrue(fileURL.lastPathComponent.hasPrefix("diagnostic-1700000000-"))
        XCTAssertEqual(try Data(contentsOf: fileURL), payload)
    }
}
