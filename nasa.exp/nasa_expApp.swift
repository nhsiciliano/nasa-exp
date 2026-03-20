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
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: FavoriteItem.self)
    }
}
