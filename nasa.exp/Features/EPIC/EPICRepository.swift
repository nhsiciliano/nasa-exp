import Foundation

protocol EPICRepositoryProtocol {
    func fetchEntries(for date: Date) async throws -> [EPICEntry]
}

struct EPICRepository: EPICRepositoryProtocol {
    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func fetchEntries(for date: Date) async throws -> [EPICEntry] {
        let dateString = Self.endpointDateFormatter.string(from: date)
        let entries: [EPICEntryDTO]

        do {
            entries = try await client.fetch([EPICEntryDTO].self, endpoint: .epicNatural(date: dateString))
        } catch NASAAPIError.serverError(let statusCode) where statusCode == 404 {
            return []
        }

        return entries.map(EPICEntry.init(dto:))
    }

    private static let endpointDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
