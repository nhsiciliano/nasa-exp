import UIKit
import UserNotifications

/// Becomes the notification center delegate at launch, before a tap on the daily APOD
/// notification can be delivered, and hands the notification's `nasaexp://` link to `deepLinkRouter`.
///
/// The delegate methods use the completion-handler variants and call the handler before returning,
/// on the main thread where the notification center delivers them. With the `async` variants Swift
/// calls the handler from the concurrency pool, and UIKit stops the app with "Call must be made on
/// main thread" when the tap brings it back from the background.
final class AppNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let deepLinkRouter = AppDeepLinkRouter()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        deepLinkRouter.openNotification(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}
