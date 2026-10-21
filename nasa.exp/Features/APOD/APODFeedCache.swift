import Foundation

/// Keeps the parsed RSS feed for a few minutes, so moving between recent days or reopening the
/// tab does not download the ~400 KB feed again.
actor APODFeedCache {
    static let shared = APODFeedCache()

    private let lifetime: TimeInterval
    private var cached: (records: [APODRecord], fetchedAt: Date)?

    init(lifetime: TimeInterval = 10 * 60) {
        self.lifetime = lifetime
    }

    func records(now: Date, load: @Sendable () async throws -> [APODRecord]) async throws -> [APODRecord] {
        if let cached, now >= cached.fetchedAt, now.timeIntervalSince(cached.fetchedAt) < lifetime {
            return cached.records
        }

        let records = try await load()
        cached = (records, now)
        return records
    }
}
