import Foundation

nonisolated protocol APODRepositoryProtocol {
    func fetchToday() async throws -> APODEntry
    func fetch(date: Date) async throws -> APODEntry
}

/// Reads APOD from science.nasa.gov: the RSS feed for today and the days it still lists, the
/// WordPress archive for older days. `APODDay` explains how ids and dates map to days.
nonisolated struct APODRepository: APODRepositoryProtocol {
    private let client: NASAClient
    private let feedCache: APODFeedCache
    private let now: @Sendable () -> Date

    init(
        client: NASAClient = NASAClient(),
        feedCache: APODFeedCache = .shared,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.client = client
        self.feedCache = feedCache
        self.now = now
    }

    func fetchToday() async throws -> APODEntry {
        do {
            guard let latest = try await feedRecords().first else {
                throw NASAAPIError.notFound
            }
            return APODEntry(record: latest)
        } catch {
            // The archive also has today's post, so a broken feed does not leave the tab empty.
            guard let url = APODSource.latestArchivePostURL else {
                throw error
            }
            return APODEntry(record: try await archiveRecord(at: url))
        }
    }

    func fetch(date: Date) async throws -> APODEntry {
        // The view model picks local calendar days; the APOD of that day has the same yyyy-MM-dd.
        let id = APODRepository.requestFormatter.string(from: date)

        // A feed failure is not fatal here: the archive has every day, including recent ones.
        if isListedInFeed(id), let record = try? await feedRecords().first(where: { $0.id == id }) {
            return APODEntry(record: record)
        }

        guard let url = APODSource.archivePostURL(for: id) else {
            throw NASAAPIError.invalidRequest
        }
        return APODEntry(record: try await archiveRecord(at: url))
    }

    /// Whether `id` is recent enough to still be in the RSS feed.
    private func isListedInFeed(_ id: String) -> Bool {
        guard let age = APODDay.days(from: id, to: APODDay.id(for: now())) else {
            return false
        }

        return (0..<APODSource.feedWindowDays).contains(age)
    }

    private func feedRecords() async throws -> [APODRecord] {
        let client = client
        return try await feedCache.records(now: now()) {
            try APODFeedParser.records(from: await client.fetchData(url: APODSource.feedURL))
        }
    }

    private func archiveRecord(at url: URL) async throws -> APODRecord {
        let posts = try await client.fetch([APODArchivePostDTO].self, url: url)
        guard let record = posts.first.flatMap(APODRecord.init(post:)) else {
            throw NASAAPIError.notFound
        }

        return record
    }

    private static let requestFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
