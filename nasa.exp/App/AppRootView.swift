import SwiftUI

struct AppRootView: View {
    @State private var selectedTab: AppTab = AppRootView.initialTab()

    var body: some View {
        ZStack {
            SpaceBackground()

            TabView(selection: $selectedTab) {
                rootNavigation {
                    APODHomeView()
                }
                .tabItem {
                    Label(AppTab.apod.title, systemImage: AppTab.apod.systemImage)
                }
                .tag(AppTab.apod)

                rootNavigation {
                    RoversHomeView()
                }
                .tabItem {
                    Label(AppTab.rovers.title, systemImage: AppTab.rovers.systemImage)
                }
                .tag(AppTab.rovers)

                rootNavigation {
                    EPICHomeView()
                }
                .tabItem {
                    Label(AppTab.epic.title, systemImage: AppTab.epic.systemImage)
                }
                .tag(AppTab.epic)

                rootNavigation {
                    FavoritesHomeView()
                }
                .tabItem {
                    Label(AppTab.favorites.title, systemImage: AppTab.favorites.systemImage)
                }
                .tag(AppTab.favorites)
            }
        }
        .tint(AppColors.accent)
        .toolbarBackground(AppColors.surfaceBase.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
    }

    /// Lets QA and simulator runs open a specific tab: `-initialTab rovers`.
    private static func initialTab() -> AppTab {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "initialTab"),
           let tab = AppTab(launchArgument: raw) {
            return tab
        }
        #endif
        return .apod
    }

    private func rootNavigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
        }
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    AppRootView()
}
