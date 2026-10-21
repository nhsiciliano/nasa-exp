import Foundation
import XCTest
@testable import nasa_exp

/// Runs with the scheme's test language (Spanish), the catalog's source language.
final class NASAAPIErrorMessageTests: XCTestCase {
    func test_rateLimitedMessage_switchesToHoursForLongWaits() {
        XCTAssertEqual(
            NASAAPIError.rateLimited(retryAfter: 23_580).errorDescription,
            "Demasiadas consultas a NASA. Probá de nuevo en 7 horas."
        )
        XCTAssertEqual(
            NASAAPIError.rateLimited(retryAfter: 90 * 60).errorDescription,
            "Demasiadas consultas a NASA. Probá de nuevo en 90 minutos."
        )
        XCTAssertEqual(
            NASAAPIError.rateLimited(retryAfter: 30).errorDescription,
            "Demasiadas consultas a NASA. Probá de nuevo en un minuto."
        )
    }
}
