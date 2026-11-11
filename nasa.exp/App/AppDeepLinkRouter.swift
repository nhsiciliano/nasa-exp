import Combine
import Foundation

/// Holds the tab a `nasaexp://` link asked for until `AppRootView` shows it. Widget links and daily
/// notification taps both land here, inside the process, so a tap that launches the app keeps its
/// destination until the root view appears.
final class AppDeepLinkRouter: ObservableObject {
    @Published private(set) var pendingTab: AppTab?

    /// Returns whether `url` is a `nasaexp://<tab>` link.
    @discardableResult
    func open(_ url: URL) -> Bool {
        guard let tab = AppTab(url: url) else {
            return false
        }

        pendingTab = tab
        return true
    }

    @discardableResult
    func openNotification(userInfo: [AnyHashable: Any]) -> Bool {
        guard let url = AppDeepLinkRouter.url(fromNotificationUserInfo: userInfo) else {
            return false
        }

        return open(url)
    }

    /// Hands the pending tab to the caller once.
    func consumePendingTab() -> AppTab? {
        defer { pendingTab = nil }
        return pendingTab
    }

    /// The link that `APODDailyReminderScheduler` stores in each daily notification.
    static func url(fromNotificationUserInfo userInfo: [AnyHashable: Any]) -> URL? {
        guard let link = userInfo[APODDailyReminderScheduler.urlKey] as? String else {
            return nil
        }

        return URL(string: link)
    }
}
