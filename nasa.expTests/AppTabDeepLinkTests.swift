import Foundation
import XCTest
@testable import nasa_exp

@MainActor
final class AppTabDeepLinkTests: XCTestCase {
    func test_appTabFromURL_whenNASAExpDeepLink_selectsMatchingTab() throws {
        XCTAssertEqual(AppTab(url: try XCTUnwrap(URL(string: "nasaexp://apod"))), .apod)
        XCTAssertEqual(AppTab(url: try XCTUnwrap(URL(string: "NASAEXP://Favorites"))), .favorites)
    }

    func test_appTabFromURL_whenOtherSchemeOrUnknownTab_returnsNil() throws {
        XCTAssertNil(AppTab(url: try XCTUnwrap(URL(string: "https://apod.nasa.gov"))))
        XCTAssertNil(AppTab(url: try XCTUnwrap(URL(string: "nasaexp://settings"))))
        XCTAssertNil(AppTab(url: try XCTUnwrap(URL(string: "nasaexp:apod"))))
    }

    func test_appTabDeepLinkURL_roundTripsForEveryTab() throws {
        for tab in [AppTab.apod, .rovers, .epic, .favorites] {
            let url = try XCTUnwrap(tab.deepLinkURL)
            XCTAssertEqual(AppTab(url: url), tab)
        }
        XCTAssertEqual(AppTab.apod.deepLinkURL?.absoluteString, "nasaexp://apod")
    }

    func test_appTabFromLaunchArgument_matchesDeepLinkNames() {
        XCTAssertEqual(AppTab(launchArgument: "EPIC"), .epic)
        XCTAssertNil(AppTab(launchArgument: "earth"))
    }
}
