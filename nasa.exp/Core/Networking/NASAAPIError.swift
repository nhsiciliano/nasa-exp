import Foundation

enum NASAAPIError: LocalizedError {
    case invalidRequest
    case missingAPIKey
    case offline
    case transportError(Error)
    case invalidResponse
    case rateLimited(retryAfter: TimeInterval?)
    case invalidAPIKey
    case serverError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return String(localized: "No se pudo crear la solicitud a NASA API.")
        case .missingAPIKey:
            return String(localized: "Falta configurar NASA_API_KEY para esta compilación.")
        case .offline:
            return String(localized: "Sin conexión con NASA. Revisá tu conexión a internet y volvé a intentar.")
        case let .transportError(error):
            return String(localized: "Error de conectividad: \(error.localizedDescription)")
        case .invalidResponse:
            return String(localized: "La respuesta del servidor es inválida.")
        case let .rateLimited(retryAfter):
            return Self.rateLimitedMessage(retryAfter: retryAfter)
        case .invalidAPIKey:
            return String(localized: "NASA rechazó la clave de acceso de la app. Probá más tarde; si sigue pasando, actualizá la app.")
        case let .serverError(statusCode):
            return String(localized: "NASA API devolvió estado HTTP \(statusCode). Probá de nuevo en unos segundos.")
        case let .decodingError(error):
            return String(localized: "No se pudo leer la respuesta: \(error.localizedDescription)")
        }
    }

    private static func rateLimitedMessage(retryAfter: TimeInterval?) -> String {
        guard let retryAfter, retryAfter > 0 else {
            return String(localized: "Demasiadas consultas a NASA. Probá de nuevo en unos minutos.")
        }

        let minutes = Int((retryAfter / 60).rounded(.up))
        if minutes > 90 {
            let hours = Int((retryAfter / 3600).rounded(.up))
            return String(localized: "Demasiadas consultas a NASA. Probá de nuevo en \(hours) horas.")
        }
        if minutes <= 1 {
            return String(localized: "Demasiadas consultas a NASA. Probá de nuevo en un minuto.")
        }

        return String(localized: "Demasiadas consultas a NASA. Probá de nuevo en \(minutes) minutos.")
    }
}
