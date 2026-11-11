import Foundation
import XCTest
@testable import nasa_exp

@MainActor
final class AppDeepLinkRouterTests: XCTestCase {
    // MARK: - Notification userInfo

    func test_urlFromNotificationUserInfo_whenDailyReminderLink_returnsAPODLink() throws {
        let userInfo: [AnyHashable: Any] = [APODDailyReminderScheduler.urlKey: "nasaexp://apod"]

        let url = try XCTUnwrap(AppDeepLinkRouter.url(fromNotificationUserInfo: userInfo))

        XCTAssertEqual(AppTab(url: url), .apod)
    }

    func test_urlFromNotificationUserInfo_whenLinkMissingOrNotText_returnsNil() {
        XCTAssertNil(AppDeepLinkRouter.url(fromNotificationUserInfo: [:]))
        XCTAssertNil(AppDeepLinkRouter.url(fromNotificationUserInfo: ["other": "nasaexp://apod"]))
        XCTAssertNil(AppDeepLinkRouter.url(fromNotificationUserInfo: [APODDailyReminderScheduler.urlKey: 42]))
    }

    func test_openNotification_whenDailyReminder_leavesAPODPending() {
        let router = AppDeepLinkRouter()

        let didOpen = router.openNotification(userInfo: [APODDailyReminderScheduler.urlKey: "nasaexp://apod"])

        XCTAssertTrue(didOpen)
        XCTAssertEqual(router.pendingTab, .apod)
    }

    func test_openNotification_whenLinkIsNotATab_leavesNothingPending() {
        let router = AppDeepLinkRouter()

        XCTAssertFalse(router.openNotification(userInfo: [APODDailyReminderScheduler.urlKey: "https://apod.nasa.gov"]))
        XCTAssertFalse(router.openNotification(userInfo: [APODDailyReminderScheduler.urlKey: "nasaexp://settings"]))
        XCTAssertFalse(router.openNotification(userInfo: [:]))
        XCTAssertNil(router.pendingTab)
    }

    // MARK: - Pending destination

    func test_consumePendingTab_whenTapArrivedBeforeTheRootView_returnsItOnlyOnce() throws {
        // Cold start: the tap is delivered while launching, before any view reads the router.
        let router = AppDeepLinkRouter()
        router.openNotification(userInfo: [APODDailyReminderScheduler.urlKey: "nasaexp://apod"])

        XCTAssertEqual(router.consumePendingTab(), .apod)
        XCTAssertNil(router.consumePendingTab())
        XCTAssertNil(router.pendingTab)
    }

    func test_open_whenSameLinkArrivesAgainAfterConsuming_isPendingAgain() throws {
        let router = AppDeepLinkRouter()
        let url = try XCTUnwrap(URL(string: "nasaexp://apod"))

        router.open(url)
        _ = router.consumePendingTab()
        router.open(url)

        XCTAssertEqual(router.pendingTab, .apod)
    }

    func test_open_whenWidgetLinkFollowsNotification_keepsTheLatestLink() throws {
        let router = AppDeepLinkRouter()

        router.openNotification(userInfo: [APODDailyReminderScheduler.urlKey: "nasaexp://apod"])
        XCTAssertTrue(router.open(try XCTUnwrap(URL(string: "nasaexp://rovers"))))

        XCTAssertEqual(router.consumePendingTab(), .rovers)
    }

    func test_open_whenOtherScheme_keepsPendingTab() throws {
        let router = AppDeepLinkRouter()
        router.open(try XCTUnwrap(URL(string: "nasaexp://epic")))

        XCTAssertFalse(router.open(try XCTUnwrap(URL(string: "https://science.nasa.gov"))))

        XCTAssertEqual(router.pendingTab, .epic)
    }
}
