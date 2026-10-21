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
            return "No se pudo crear la solicitud a NASA API."
        case .missingAPIKey:
            return "Falta configurar NASA_API_KEY para esta compilación."
        case .offline:
            return "Sin conexión con NASA. Revisá tu conexión a internet y volvé a intentar."
        case let .transportError(error):
            return "Error de conectividad: \(error.localizedDescription)"
        case .invalidResponse:
            return "La respuesta del servidor es inválida."
        case let .rateLimited(retryAfter):
            return Self.rateLimitedMessage(retryAfter: retryAfter)
        case .invalidAPIKey:
            return "NASA rechazó la clave de acceso de la app. Probá más tarde; si sigue pasando, actualizá la app."
        case let .serverError(statusCode):
            return "NASA API devolvió estado HTTP \(statusCode). Probá de nuevo en unos segundos."
        case let .decodingError(error):
            return "No se pudo leer la respuesta: \(error.localizedDescription)"
        }
    }

    private static func rateLimitedMessage(retryAfter: TimeInterval?) -> String {
        guard let retryAfter, retryAfter > 0 else {
            return "Demasiadas consultas a NASA. Probá de nuevo en unos minutos."
        }

        let minutes = Int((retryAfter / 60).rounded(.up))
        if minutes <= 1 {
            return "Demasiadas consultas a NASA. Probá de nuevo en un minuto."
        }

        return "Demasiadas consultas a NASA. Probá de nuevo en \(minutes) minutos."
    }
}
