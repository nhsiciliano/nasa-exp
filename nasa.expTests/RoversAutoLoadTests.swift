import Foundation
import XCTest
@testable import nasa_exp

@MainActor
final class RoversAutoLoadTests: XCTestCase {
    func test_loadMoreIfNeeded_whenLastPhotoAppears_loadsNextPage() async throws {
        let repository = PagedRoversRepository(pages: [
            0: RoverPhotoPage(photos: Self.makePhotos(range: 0..<40), total: 70, hasMore: true),
            1: RoverPhotoPage(photos: Self.makePhotos(range: 40..<70), total: 70, hasMore: false)
        ])
        let viewModel = RoversViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        guard case let .loaded(feed) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        await viewModel.loadMoreIfNeeded(after: try XCTUnwrap(feed.photos.last))

        guard case let .loaded(expanded) = viewModel.state else {
            return XCTFail("Expected loaded state after auto load")
        }
        XCTAssertEqual(expanded.photos.count, 70)
        XCTAssertEqual(repository.requestedPages, [0, 1])
    }

    func test_loadMoreIfNeeded_whenPhotoIsNotLast_doesNothing() async throws {
        let repository = PagedRoversRepository(pages: [
            0: RoverPhotoPage(photos: Self.makePhotos(range: 0..<40), total: 70, hasMore: true),
            1: RoverPhotoPage(photos: Self.makePhotos(range: 40..<70), total: 70, hasMore: false)
        ])
        let viewModel = RoversViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        guard case let .loaded(feed) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }

        await viewModel.loadMoreIfNeeded(after: try XCTUnwrap(feed.photos.first))

        XCTAssertEqual(repository.requestedPages, [0])
    }

    func test_loadMoreIfNeeded_afterFailedPage_waitsForManualRetry() async throws {
        let repository = PagedRoversRepository(
            pages: [
                0: RoverPhotoPage(photos: Self.makePhotos(range: 0..<40), total: 70, hasMore: true),
                1: RoverPhotoPage(photos: Self.makePhotos(range: 40..<70), total: 70, hasMore: false)
            ],
            failingPages: [1]
        )
        let viewModel = RoversViewModel(repository: repository)
        await viewModel.loadIfNeeded()

        guard case let .loaded(feed) = viewModel.state else {
            return XCTFail("Expected loaded state")
        }
        let lastPhoto = try XCTUnwrap(feed.photos.last)

        await viewModel.loadMoreIfNeeded(after: lastPhoto)
        XCTAssertNotNil(viewModel.loadMoreErrorMessage)
        XCTAssertEqual(repository.attemptedPages, [0, 1])

        await viewModel.loadMoreIfNeeded(after: lastPhoto)
        XCTAssertEqual(repository.attemptedPages, [0, 1], "Auto load must not retry in a loop after a failure")

        repository.failingPages = []
        await viewModel.loadMore()

        guard case let .loaded(expanded) = viewModel.state else {
            return XCTFail("Expected loaded state after manual retry")
        }
        XCTAssertEqual(expanded.photos.count, 70)
        XCTAssertNil(viewModel.loadMoreErrorMessage)
    }

    private static func makePhotos(range: Range<Int>) -> [RoverPhoto] {
        range.map { index in
            RoverPhoto(
                id: "msl-\(index)",
                rover: .curiosity,
                sol: 5050,
                instrument: "NAV_LEFT_B",
                cameraName: "Navcam",
                cameraFullName: "Navigation Camera",
                thumbnailURL: URL(string: "https://example.com/\(index).jpg"),
                imageURL: URL(string: "https://example.com/\(index).jpg"),
                earthDate: nil,
                caption: "Sample",
                credit: "NASA/JPL-Caltech"
            )
        }
    }
}

private enum PagedRoversError: LocalizedError {
    case pageFailed

    var errorDescription: String? {
        "Page failed"
    }
}

private final class PagedRoversRepository: RoversRepositoryProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private let pages: [Int: RoverPhotoPage]
    private var storedFailingPages: Set<Int>
    private var storedAttemptedPages: [Int] = []

    init(pages: [Int: RoverPhotoPage], failingPages: Set<Int> = []) {
        self.pages = pages
        self.storedFailingPages = failingPages
    }

    var failingPages: Set<Int> {
        get { lock.withLock { storedFailingPages } }
        set { lock.withLock { storedFailingPages = newValue } }
    }

    var attemptedPages: [Int] {
        lock.withLock { storedAttemptedPages }
    }

    var requestedPages: [Int] {
        attemptedPages
    }

    func fetchLatestSol(for rover: RoverName) async throws -> Int {
        5050
    }

    func fetchPhotos(rover: RoverName, sol: Int, camera: RoverCamera, page: Int) async throws -> RoverPhotoPage {
        let shouldFail = lock.withLock {
            storedAttemptedPages.append(page)
            return storedFailingPages.contains(page)
        }

        if shouldFail {
            throw PagedRoversError.pageFailed
        }
        return pages[page] ?? RoverPhotoPage(photos: [], total: 0, hasMore: false)
    }
}
