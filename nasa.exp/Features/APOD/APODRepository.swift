import Foundation

nonisolated protocol APODRepositoryProtocol {
    func fetchToday() async throws -> APODEntry
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
}
