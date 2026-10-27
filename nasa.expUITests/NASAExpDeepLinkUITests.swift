import XCTest

/// Opens `nasaexp://` links in the running app, the way the APOD widget does, and checks that each
/// one selects its tab.
final class NASAExpDeepLinkUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        // Spanish is the base language; pinning it keeps label-based queries stable.
        app.launchArguments += ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES", "-initialTab", "rovers"]
        app.launch()
    }

    func test_openURL_selectsTabOfDeepLink() throws {
        XCTAssertTrue(element("Seleccionar rover").waitForExistence(timeout: 10), "App did not start on Rovers")

        app.open(try XCTUnwrap(URL(string: "nasaexp://favorites")))
        XCTAssertTrue(element("Acerca de NASA Exp").waitForExistence(timeout: 10), "nasaexp://favorites did not open Favorites")

        app.open(try XCTUnwrap(URL(string: "nasaexp://apod")))
        XCTAssertTrue(element("Fecha aleatoria").waitForExistence(timeout: 10), "nasaexp://apod did not open APOD")
    }

    private func element(_ identifierOrLabel: String) -> XCUIElement {
        app.descendants(matching: .any)[identifierOrLabel].firstMatch
    }
}
