import Foundation
import Combine

@MainActor
final class RoversViewModel: ObservableObject {
    enum ViewState {
        case idle
        case loading
        case loaded([RoverPhoto])
        case failed(String)
    }

    @Published var selectedRover: RoverName = .curiosity {
        didSet {
            if !availableCameras.contains(selectedCamera) {
                selectedCamera = .all
            }

            if oldValue != selectedRover {
                selectedDate = defaultRoverDate(for: selectedRover)
            }
        }
    }
    @Published var selectedDate: Date = defaultRoverDate(for: .curiosity)
    @Published var selectedCamera: RoverCamera = .all
    @Published private(set) var state: ViewState = .idle
    @Published private(set) var isSearching = false

    var availableCameras: [RoverCamera] {
        RoverCamera.options(for: selectedRover)
    }

    var maxSelectableDate: Date {
        Calendar.current.startOfDay(for: .now)
    }

    private let repository: RoversRepositoryProtocol

    init(repository: RoversRepositoryProtocol) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: RoversRepository())
    }

    func loadIfNeeded() async {
        guard case .idle = state else {
            return
        }

        await search()
    }

    func search() async {
        guard !isSearching else {
            return
        }

        isSearching = true
        state = .loading

        if selectedDate > maxSelectableDate {
            selectedDate = maxSelectableDate
        }

        do {
            let photos = try await repository.fetchPhotos(
                rover: selectedRover,
                earthDate: selectedDate,
                camera: selectedCamera
            )
            state = .loaded(Array(photos.prefix(100)))
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            state = .failed(message)
        }

        isSearching = false
    }
}

private func defaultRoverDate(for rover: RoverName) -> Date {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"

    let fallback = Calendar.current.date(byAdding: .day, value: -14, to: .now) ?? .now

    switch rover {
    case .curiosity:
        return formatter.date(from: "2015-06-03") ?? fallback
    case .opportunity:
        return formatter.date(from: "2010-06-15") ?? fallback
    case .spirit:
        return formatter.date(from: "2008-03-01") ?? fallback
    case .perseverance:
        return formatter.date(from: "2021-03-01") ?? fallback
    }
}
