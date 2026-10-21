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
        }
        .modelContainer(for: FavoriteItem.self)
    }
}
