import Foundation

enum NASAAPIError: LocalizedError {
    case invalidRequest
    case missingAPIKey
    case transportError(Error)
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "No se pudo crear la solicitud a NASA API."
        case .missingAPIKey:
            return "Falta configurar NASA_API_KEY para esta compilacion."
        case let .transportError(error):
            return "Error de conectividad: \(error.localizedDescription)"
        case .invalidResponse:
            return "La respuesta del servidor es invalida."
        case let .serverError(statusCode):
            return "NASA API devolvio estado HTTP \(statusCode)."
        case let .decodingError(error):
            return "No se pudo leer la respuesta: \(error.localizedDescription)"
        }
    }
}
