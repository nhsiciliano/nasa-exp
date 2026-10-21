import Foundation

nonisolated enum NASAEnvironment {
    static var apiBaseURL: URL {
        URL(string: "https://api.nasa.gov")!
    }

    static var apiKey: String {
        if let envValue = ProcessInfo.processInfo.environment["NASA_API_KEY"]?.trimmedNonEmpty {
            return envValue
        }

        if let plistValue = (Bundle.main.object(forInfoDictionaryKey: "NASA_API_KEY") as? String)?.trimmedNonEmpty,
           plistValue != "$(NASA_API_KEY)",
           plistValue.lowercased() != "your_api_key_here" {
            return plistValue
        }

        #if DEBUG
        return "DEMO_KEY"
        #else
        return ""
        #endif
    }

    static var hasValidAPIKey: Bool {
        !apiKey.isEmpty
    }
}

nonisolated private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
