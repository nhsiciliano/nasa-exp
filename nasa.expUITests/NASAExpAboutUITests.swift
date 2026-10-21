import XCTest

/// The About screen carries the "not an official NASA app" notice, so it has to stay reachable from Favorites.
final class NASAExpAboutUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Spanish is the base language; pinning it keeps label-based queries stable.
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()
    }

    func test_favoritesTab_opensAboutScreenWithDisclaimerAndSources() {
        let favoritesTab = app.tabBars.buttons["Favoritos"]
        XCTAssertTrue(favoritesTab.waitForExistence(timeout: 10), "Favorites tab not found")
        favoritesTab.tap()

        let aboutButton = app.buttons["Acerca de NASA Exp"]
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 10), "About button missing")
        aboutButton.tap()

        let disclaimer = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'no es una app oficial de la NASA'")).firstMatch
        XCTAssertTrue(disclaimer.waitForExistence(timeout: 10), "Disclaimer missing")
        XCTAssertTrue(app.staticTexts["science.nasa.gov/apod"].exists)
        XCTAssertTrue(app.staticTexts["mars.nasa.gov"].exists)
        XCTAssertTrue(app.staticTexts["epic.gsfc.nasa.gov"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "about"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        app.buttons["Cerrar"].tap()
        XCTAssertTrue(aboutButton.waitForExistence(timeout: 10), "About sheet did not close")
    }
}
