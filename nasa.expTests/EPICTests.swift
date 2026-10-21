import Foundation
import XCTest
@testable import nasa_exp

final class EPICEntryURLTests: XCTestCase {
    func test_entryFromDTO_buildsFullImageAndThumbnailURLsWithoutAPIKey() throws {
        let entry = EPICEntry(dto: try makeDTO(image: "epic_1b_20260313000831", date: "2026-03-13 00:03:31"))

        XCTAssertEqual(
            entry.imageURL?.absoluteString,
            "https://epic.gsfc.nasa.gov/archive/natural/2026/03/13/png/epic_1b_20260313000831.png"
        )
        XCTAssertEqual(
            entry.thumbnailURL?.absoluteString,
            "https://epic.gsfc.nasa.gov/archive/natural/2026/03/13/thumbs/epic_1b_20260313000831.jpg"
        )
        XCTAssertFalse(entry.imageURL?.absoluteString.contains("api_key") ?? true)
        XCTAssertFalse(entry.thumbnailURL?.absoluteString.contains("api_key") ?? true)
    }

    private func makeDTO(image: String, date: String) throws -> EPICEntryDTO {
        let json = """
        {
          "identifier": "20260313000831",
          "caption": "Sample EPIC caption for tests",
          "image": "\(image)",
          "date": "\(date)",
          "centroid_coordinates": { "lat": 12.34, "lon": -56.78 }
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(EPICEntryDTO.self, from: json)
    }
}

final class EPICEndpointTests: XCTestCase {
    func test_epicLatest_usesUnfilteredNaturalPath() {
        XCTAssertEqual(NASAEndpoint.epicLatest.path, "/EPIC/api/natural")
        XCTAssertEqual(NASAEndpoint.epicNatural(date: "2026-03-13").path, "/EPIC/api/natural/date/2026-03-13")
    }
}

@MainActor
final class EPICViewModelTests: XCTestCase {
    func test_loadIfNeeded_usesLatestEntriesAndMovesSelectedDate() async {
        let latest = Self.makeEntry(identifier: "20260313000831", date: Self.date(year: 2026, month: 3, day: 13))
        let repository = MockEPICRepository(latest: .success([latest]))
        let viewModel = EPICViewModel(repository: repository, searchDebounce: .milliseconds(10))

        await viewModel.loadIfNeeded()

        guard case let .loaded(entries) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        XCTAssertEqual(entries.map(\.id), ["20260313000831"])
        XCTAssertEqual(Calendar.current.startOfDay(for: viewModel.selectedDate), Calendar.current.startOfDay(for: latest.date))
        XCTAssertEqual(repository.latestCallCount, 1)
        XCTAssertEqual(repository.datedCalls.count, 0)
    }

    func test_loadIfNeeded_doesNotTriggerAutomaticSearchForLatestDate() async throws {
        let latest = Self.makeEntry(identifier: "20260313000831", date: Self.date(year: 2026, month: 3, day: 13))
        let repository = MockEPICRepository(latest: .success([latest]))
        let viewModel = EPICViewModel(repository: repository, searchDebounce: .milliseconds(10))

        await viewModel.loadIfNeeded()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(repository.datedCalls.count, 0)
    }

    func test_loadIfNeeded_setsFailedStateOnError() async {
        let repository = MockEPICRepository(latest: .failure(MockEPICError.sample))
        let viewModel = EPICViewModel(repository: repository, searchDebounce: .milliseconds(10))

        await viewModel.loadIfNeeded()

        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertTrue(message.contains("Sample failure"))
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_changingSelectedDate_searchesOnceAfterDebounce() async throws {
        let repository = MockEPICRepository(latest: .success([]))
        let viewModel = EPICViewModel(repository: repository, searchDebounce: .milliseconds(50))
        let targetDate = Self.date(year: 2026, month: 2, day: 10)

        viewModel.selectedDate = Self.date(year: 2026, month: 2, day: 8)
        viewModel.selectedDate = Self.date(year: 2026, month: 2, day: 9)
        viewModel.selectedDate = targetDate

        try await waitUntil { repository.datedCalls.count >= 1 }
        try await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(repository.datedCalls.count, 1)
        XCTAssertEqual(Calendar.current.startOfDay(for: repository.datedCalls[0]), Calendar.current.startOfDay(for: targetDate))
    }

    private static func date(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .now
    }

    private static func makeEntry(identifier: String, date: Date) -> EPICEntry {
        EPICEntry(
            id: identifier,
            title: "EPIC - \(identifier)",
            caption: "Sample",
            date: date,
            latitude: 0,
            longitude: 0,
            imageURL: nil,
            thumbnailURL: nil
        )
    }

    private func waitUntil(timeout: Duration = .seconds(2), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else {
                return XCTFail("Timed out waiting for condition")
            }
            try await Task.sleep(for: .milliseconds(10))
        }
    }
}

private enum MockEPICError: LocalizedError {
    case sample

    var errorDescription: String? {
        "Sample failure"
    }
}

private final class MockEPICRepository: EPICRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private let latest: Result<[EPICEntry], Error>
    private var recordedLatestCalls = 0
    private var recordedDatedCalls: [Date] = []

    init(latest: Result<[EPICEntry], Error>) {
        self.latest = latest
    }

    var latestCallCount: Int {
        lock.withLock { recordedLatestCalls }
    }

    var datedCalls: [Date] {
        lock.withLock { recordedDatedCalls }
    }

    func fetchEntries(for date: Date) async throws -> [EPICEntry] {
        lock.withLock { recordedDatedCalls.append(date) }
        return []
    }

    func fetchLatest() async throws -> [EPICEntry] {
        lock.withLock { recordedLatestCalls += 1 }
        return try latest.get()
    }
}
