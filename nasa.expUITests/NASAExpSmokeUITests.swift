import XCTest

/// Smoke test over the live NASA feeds: every tab opens and a Rovers and an EPIC detail can be reached.
/// When a feed answers with an error the detail checks are skipped, so a backend outage or a
/// `DEMO_KEY` rate limit on CI shows up as a skip instead of a broken build.
final class NASAExpSmokeUITests: XCTestCase {
    private let networkTimeout: TimeInterval = 45
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Spanish is the base language; pinning it keeps label-based queries stable.
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()
    }

    func test_eachTab_opensItsScreen() {
        openTab("Hoy")
        XCTAssertTrue(element("Fecha aleatoria").waitForExistence(timeout: 10), "APOD date controls missing")

        openTab("Rovers")
        XCTAssertTrue(element("Seleccionar rover").waitForExistence(timeout: 10), "Rovers filters missing")

        openTab("Tierra")
        XCTAssertTrue(element("Seleccionar fecha EPIC").waitForExistence(timeout: 10), "EPIC date picker missing")

        openTab("Favoritos")
        // The type filter only appears once something is saved; the About button is on both states.
        XCTAssertTrue(element("Acerca de NASA Exp").waitForExistence(timeout: 10), "Favorites screen missing")
    }

    func test_roversTab_opensPhotoDetail() throws {
        openTab("Rovers")

        let card = try firstResult(identifier: "rovers.photoCard", errorIdentifier: "rovers.retry", feed: "Rovers")
        card.tap()

        XCTAssertTrue(app.navigationBars["Detalle Rover"].waitForExistence(timeout: 10))
    }

    func test_epicTab_opensImageDetail() throws {
        openTab("Tierra")

        let card = try firstResult(identifier: "epic.card", errorIdentifier: "epic.retry", feed: "EPIC")
        card.tap()

        XCTAssertTrue(app.navigationBars["Detalle EPIC"].waitForExistence(timeout: 10))
    }

    // MARK: - Helpers

    /// Tab bar buttons don't inherit identifiers set inside `.tabItem`, so tabs are found by their Spanish label.
    private func openTab(_ label: String) {
        let tab = app.tabBars.buttons[label]
        XCTAssertTrue(tab.waitForExistence(timeout: 10), "Tab \(label) not found")
        tab.tap()
    }

    private func element(_ identifierOrLabel: String) -> XCUIElement {
        app.descendants(matching: .any)[identifierOrLabel].firstMatch
    }

    /// Waits for the first card of a feed, scrolling it into view; skips when the feed shows its error state.
    private func firstResult(identifier: String, errorIdentifier: String, feed: String) throws -> XCUIElement {
        let card = app.buttons.matching(identifier: identifier).firstMatch
        let errorRetry = app.buttons[errorIdentifier]

        let deadline = Date().addingTimeInterval(networkTimeout)
        var swipesLeft = 3
        while !card.exists, Date() < deadline {
            if errorRetry.exists {
                throw XCTSkip("\(feed) feed returned an error; detail navigation not checked.")
            }
            if !card.waitForExistence(timeout: 5), swipesLeft > 0 {
                // Lazy grids only expose cells near the viewport.
                app.swipeUp()
                swipesLeft -= 1
            }
        }
        XCTAssertTrue(card.exists, "\(feed) feed showed no results within \(Int(networkTimeout))s")

        for _ in 0..<5 where !card.isHittable {
            app.swipeUp()
        }

        return card
    }
}
