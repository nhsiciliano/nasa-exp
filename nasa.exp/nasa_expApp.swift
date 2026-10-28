//
//  nasa_expApp.swift
//  nasa.exp
//
//  Created by Nicolas Siciliano on 09/03/2026.
//

import SwiftUI
import SwiftData

@main
struct nasa_expApp: App {
    @UIApplicationDelegateAdaptor(AppNotificationDelegate.self) private var notificationDelegate

    init() {
        URLCache.shared = URLCache(
            memoryCapacity: 50 * 1024 * 1024,
            diskCapacity: 300 * 1024 * 1024
        )
        MetricKitReporter.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .task {
                    // Tops up the daily reminder window; does nothing until the user opts in.
                    await APODDailyReminderRefresher().refresh()
                }
        }
        .modelContainer(for: FavoriteItem.self)
        .backgroundTask(.appRefresh(APODDailyReminderRefresher.taskIdentifier)) {
            await APODDailyReminderRefresher().refresh()
        }
    }
}
