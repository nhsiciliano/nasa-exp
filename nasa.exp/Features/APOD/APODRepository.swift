import Foundation

nonisolated protocol APODRepositoryProtocol {
    func fetchToday() async throws -> APODEntry
    func fetch(date: Date) async throws -> APODEntry
}

nonisolated struct APODRepository: APODRepositoryProtocol {
    private let client: NASAClient

    init(client: NASAClient = NASAClient()) {
        self.client = client
    }

    func fetchToday() async throws -> APODEntry {
        let dto = try await client.fetch(APODResponseDTO.self, endpoint: .apod(date: nil))
        return APODEntry(dto: dto)
    }

    func fetch(date: Date) async throws -> APODEntry {
        let dto = try await client.fetch(
            APODResponseDTO.self,
            endpoint: .apod(date: APODRepository.requestFormatter.string(from: date))
        )
        return APODEntry(dto: dto)
    }

    private static let requestFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
