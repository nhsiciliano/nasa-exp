import UIKit
import UserNotifications

/// Becomes the notification center delegate at launch, before a tap on the daily APOD
/// notification can be delivered, and opens the notification's `nasaexp://` link.
final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard let link = response.notification.request.content.userInfo[APODDailyReminderScheduler.urlKey] as? String,
              let url = URL(string: link) else {
            return
        }

        await open(url)
    }

    /// Goes through the same `onOpenURL` in `AppRootView` as the widget links.
    private func open(_ url: URL) {
        UIApplication.shared.open(url)
    }
}
