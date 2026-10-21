import Foundation
import XCTest
@testable import nasa_exp

@MainActor
final class APODViewModelTests: XCTestCase {
    private let calendar = Calendar.current

    func test_loadIfNeeded_requestsTodayAndShowsLatest() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-21")
        let viewModel = makeViewModel(repository: repository, now: day(2026, 10, 21, hour: 15))

        await viewModel.loadIfNeeded()

        XCTAssertEqual(repository.todayRequestCount, 1)
        XCTAssertTrue(repository.requestedDates.isEmpty)
        XCTAssertTrue(viewModel.isShowingLatest)
        XCTAssertFalse(viewModel.canGoToNextDay)
        XCTAssertTrue(viewModel.canGoToPreviousDay)
        XCTAssertEqual(loadedEntryID(viewModel), "2026-10-21")
    }

    func test_loadIfNeeded_whenNASATodayIsBehindLocalToday_usesNASADateAsLatest() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-20")
        let viewModel = makeViewModel(repository: repository, now: day(2026, 10, 21))

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.latestDate, day(2026, 10, 20))
        XCTAssertEqual(viewModel.selectedDate, day(2026, 10, 20))
        XCTAssertTrue(viewModel.isShowingLatest)
        XCTAssertFalse(viewModel.canGoToNextDay)
    }

    func test_goToPreviousDay_thenNextDay_walksBackToLatest() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-21")
        let viewModel = makeViewModel(repository: repository, now: day(2026, 10, 21))
        await viewModel.loadIfNeeded()

        await viewModel.goToPreviousDay()

        XCTAssertEqual(viewModel.selectedDate, day(2026, 10, 20))
        XCTAssertEqual(repository.requestedDates, [day(2026, 10, 20)])
        XCTAssertFalse(viewModel.isShowingLatest)
        XCTAssertTrue(viewModel.canGoToNextDay)
        XCTAssertEqual(loadedEntryID(viewModel), "2026-10-20")

        await viewModel.goToNextDay()

        XCTAssertEqual(viewModel.selectedDate, day(2026, 10, 21))
        XCTAssertTrue(viewModel.isShowingLatest)
        XCTAssertEqual(repository.todayRequestCount, 2)
        XCTAssertEqual(repository.requestedDates, [day(2026, 10, 20)])
    }

    func test_goToNextDay_whenShowingLatest_doesNothing() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-21")
        let viewModel = makeViewModel(repository: repository, now: day(2026, 10, 21))
        await viewModel.loadIfNeeded()

        await viewModel.goToNextDay()

        XCTAssertEqual(viewModel.selectedDate, day(2026, 10, 21))
        XCTAssertEqual(repository.todayRequestCount, 1)
        XCTAssertTrue(repository.requestedDates.isEmpty)
    }

    func test_load_clampsDatesOutsideTheArchive() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-21")
        let viewModel = makeViewModel(repository: repository, now: day(2026, 10, 21))

        await viewModel.load(date: day(1990, 1, 1))

        XCTAssertEqual(viewModel.selectedDate, day(1995, 6, 16))
        XCTAssertFalse(viewModel.canGoToPreviousDay)
        XCTAssertEqual(repository.requestedDates, [day(1995, 6, 16)])

        await viewModel.goToPreviousDay()

        XCTAssertEqual(repository.requestedDates, [day(1995, 6, 16)])

        await viewModel.load(date: day(2030, 1, 1))

        XCTAssertEqual(viewModel.selectedDate, day(2026, 10, 21))
        XCTAssertTrue(viewModel.isShowingLatest)
        XCTAssertEqual(repository.todayRequestCount, 1)
    }

    func test_goToRandomDate_loadsDayAtInjectedOffsetWithinArchive() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-21")
        var receivedRange: ClosedRange<Int>?
        let viewModel = APODViewModel(
            repository: repository,
            calendar: calendar,
            now: day(2026, 10, 21),
            randomDayOffset: { range in
                receivedRange = range
                return 10
            }
        )

        await viewModel.goToRandomDate()

        let expectedDayCount = calendar.dateComponents([.day], from: day(1995, 6, 16), to: day(2026, 10, 21)).day
        XCTAssertEqual(receivedRange?.lowerBound, 0)
        XCTAssertEqual(receivedRange?.upperBound, expectedDayCount)
        XCTAssertEqual(viewModel.selectedDate, day(1995, 6, 26))
        XCTAssertEqual(repository.requestedDates, [day(1995, 6, 26)])
    }

    func test_load_whenRequestFails_showsErrorAndKeepsSelectedDate() async {
        let repository = DateRecordingAPODRepository(todayDate: "2026-10-21", dateError: NASAAPIError.rateLimited(retryAfter: nil))
        let viewModel = makeViewModel(repository: repository, now: day(2026, 10, 21))

        await viewModel.load(date: day(2020, 2, 29))

        XCTAssertEqual(viewModel.selectedDate, day(2020, 2, 29))
        guard case let .failed(message) = viewModel.state else {
            return XCTFail("Expected failed state")
        }
        XCTAssertEqual(message, NASAAPIError.rateLimited(retryAfter: nil).errorDescription)
    }

    // MARK: - Helpers

    private func makeViewModel(repository: DateRecordingAPODRepository, now: Date) -> APODViewModel {
        APODViewModel(repository: repository, calendar: calendar, now: now, randomDayOffset: { $0.lowerBound })
    }

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func loadedEntryID(_ viewModel: APODViewModel) -> String? {
        guard case let .loaded(entry) = viewModel.state else {
            return nil
        }
        return entry.id
    }
}

private final class DateRecordingAPODRepository: APODRepositoryProtocol {
    let todayDate: String
    let dateError: Error?
    private(set) var todayRequestCount = 0
    private(set) var requestedDates: [Date] = []

    init(todayDate: String, dateError: Error? = nil) {
        self.todayDate = todayDate
        self.dateError = dateError
    }

    func fetchToday() async throws -> APODEntry {
        todayRequestCount += 1
        return makeEntry(date: todayDate)
    }

    func fetch(date: Date) async throws -> APODEntry {
        requestedDates.append(date)
        if let dateError {
            throw dateError
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return makeEntry(date: formatter.string(from: date))
    }

    private func makeEntry(date: String) -> APODEntry {
        APODEntry(dto: APODResponseDTO(
            title: "APOD \(date)",
            explanation: "Sample",
            date: date,
            mediaType: "image",
            url: "https://example.com/\(date).jpg",
            hdurl: nil,
            copyright: nil
        ))
    }
}
