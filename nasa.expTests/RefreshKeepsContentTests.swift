import Foundation
import XCTest
@testable import nasa_exp

@MainActor
final class RefreshKeepsContentTests: XCTestCase {
    func test_apodRefresh_keepsLoadedEntryWhileRequestIsInFlight() async throws {
        let gate = RequestGate()
        let viewModel = APODViewModel(repository: GatedAPODRepository(gate: gate))
        await viewModel.loadIfNeeded()

        gate.close()
        let refresh = Task { await viewModel.refresh() }
        try await waitUntil { gate.waitingCount == 1 }

        guard case .loaded = viewModel.state else {
            gate.open()
            return XCTFail("Expected the entry to stay on screen during refresh")
        }

        gate.open()
        await refresh.value

        guard case .loaded = viewModel.state else {
            return XCTFail("Expected loaded state after refresh")
        }
    }

    func test_apodLoadingAnotherDate_showsLoadingState() async throws {
        let gate = RequestGate()
        let viewModel = APODViewModel(repository: GatedAPODRepository(gate: gate))
        await viewModel.loadIfNeeded()

        gate.close()
        let navigation = Task { await viewModel.goToPreviousDay() }
        try await waitUntil { gate.waitingCount == 1 }

        guard case .loading = viewModel.state else {
            gate.open()
            return XCTFail("Expected loading state when the date changes")
        }

        gate.open()
        await navigation.value
    }

    func test_epicRefresh_keepsLoadedEntriesWhileRequestIsInFlight() async throws {
        let gate = RequestGate()
        let viewModel = EPICViewModel(repository: GatedEPICRepository(gate: gate), searchDebounce: .seconds(60))
        await viewModel.search()

        gate.close()
        let refresh = Task { await viewModel.refresh() }
        try await waitUntil { gate.waitingCount == 1 }

        guard case .loaded = viewModel.state else {
            gate.open()
            return XCTFail("Expected entries to stay on screen during refresh")
        }
        XCTAssertTrue(viewModel.isSearching)

        gate.open()
        await refresh.value
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_epicSearch_showsLoadingState() async throws {
        let gate = RequestGate()
        let viewModel = EPICViewModel(repository: GatedEPICRepository(gate: gate), searchDebounce: .seconds(60))
        await viewModel.search()

        gate.close()
        let search = Task { await viewModel.search() }
        try await waitUntil { gate.waitingCount == 1 }

        guard case .loading = viewModel.state else {
            gate.open()
            return XCTFail("Expected loading state for an explicit search")
        }

        gate.open()
        await search.value
    }

    func test_roversRefresh_keepsLoadedFeedWhileRequestIsInFlight() async throws {
        let gate = RequestGate()
        let viewModel = RoversViewModel(repository: GatedRoversRepository(gate: gate))
        await viewModel.loadIfNeeded()

        gate.close()
        let refresh = Task { await viewModel.refresh() }
        try await waitUntil { gate.waitingCount == 1 }

        guard case let .loaded(feed) = viewModel.state else {
            gate.open()
            return XCTFail("Expected photos to stay on screen during refresh")
        }
        XCTAssertEqual(feed.photos.count, 1)

        gate.open()
        await refresh.value
        XCTAssertFalse(viewModel.isSearching)
    }

    func test_roversSearch_showsLoadingState() async throws {
        let gate = RequestGate()
        let viewModel = RoversViewModel(repository: GatedRoversRepository(gate: gate))
        await viewModel.loadIfNeeded()

        gate.close()
        let search = Task { await viewModel.search() }
        try await waitUntil { gate.waitingCount == 1 }

        guard case .loading = viewModel.state else {
            gate.open()
            return XCTFail("Expected loading state for an explicit search")
        }

        gate.open()
        await search.value
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

/// Lets a test hold repository calls in flight: calls pass straight through while open.
private final class RequestGate: @unchecked Sendable {
    private let lock = NSLock()
    private var isOpen = true
    private var continuations: [CheckedContinuation<Void, Never>] = []

    var waitingCount: Int {
        lock.withLock { continuations.count }
    }

    func close() {
        lock.withLock { isOpen = false }
    }

    func open() {
        let pending = lock.withLock {
            isOpen = true
            let pending = continuations
            continuations = []
            return pending
        }
        pending.forEach { $0.resume() }
    }

    func passThrough() async {
        await withCheckedContinuation { continuation in
            let shouldResume = lock.withLock {
                if !isOpen {
                    continuations.append(continuation)
                }
                return isOpen
            }
            if shouldResume {
                continuation.resume()
            }
        }
    }
}

private struct GatedAPODRepository: APODRepositoryProtocol {
    let gate: RequestGate

    func fetchToday() async throws -> APODEntry {
        await gate.passThrough()
        return Self.entry(date: "2026-03-13")
    }

    func fetch(date: Date) async throws -> APODEntry {
        await gate.passThrough()
        return Self.entry(date: "2026-03-12")
    }

    private static func entry(date: String) -> APODEntry {
        APODEntry(record: APODRecord(
            id: date,
            title: "Nebula",
            explanation: "A bright nebula.",
            credit: nil,
            pageURL: URL(string: "https://example.com/apod-\(date)/"),
            imageURL: URL(string: "https://example.com/apod.jpg"),
            videoURL: nil
        ))
    }
}

private struct GatedEPICRepository: EPICRepositoryProtocol {
    let gate: RequestGate

    func fetchEntries(for date: Date) async throws -> [EPICEntry] {
        await gate.passThrough()
        return [Self.entry]
    }

    func fetchLatest() async throws -> [EPICEntry] {
        await gate.passThrough()
        return [Self.entry]
    }

    private static let entry = EPICEntry(
        id: "20260313000831",
        title: "EPIC - 20260313000831",
        caption: "Sample",
        date: .now,
        latitude: 0,
        longitude: 0,
        imageURL: nil,
        thumbnailURL: nil
    )
}

private struct GatedRoversRepository: RoversRepositoryProtocol {
    let gate: RequestGate

    func fetchLatestSol(for rover: RoverName) async throws -> Int {
        5050
    }

    func fetchPhotos(rover: RoverName, sol: Int, camera: RoverCamera, page: Int) async throws -> RoverPhotoPage {
        await gate.passThrough()
        let photo = RoverPhoto(
            id: "msl-0",
            rover: .curiosity,
            sol: 5050,
            instrument: "NAV_LEFT_B",
            cameraName: "Navcam",
            cameraFullName: "Navigation Camera",
            thumbnailURL: nil,
            imageURL: nil,
            earthDate: nil,
            caption: "Sample",
            credit: "NASA/JPL-Caltech"
        )
        return RoverPhotoPage(photos: [photo], total: 1, hasMore: false)
    }
}
