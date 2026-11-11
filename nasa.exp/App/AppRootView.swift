import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var deepLinkRouter: AppDeepLinkRouter
    @State private var selectedTab: AppTab = AppRootView.initialTab()
    @State private var apodPath = NavigationPath()
    /// Bumped by every `nasaexp://apod` link so the APOD tab goes back to the latest entry.
    @State private var apodLatestRequest = 0

    var body: some View {
        ZStack {
            SpaceBackground()

            TabView(selection: $selectedTab) {
                NavigationStack(path: $apodPath) {
                    APODHomeView(latestRequest: apodLatestRequest)
                }
                .rootNavigationChrome()
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
        .preferredColorScheme(.dark)
        .toolbarBackground(AppColors.surfaceBase.opacity(0.98), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .onOpenURL { url in
            deepLinkRouter.open(url)
        }
        // A notification tap that launches the app can arrive before this view exists.
        .onAppear(perform: showPendingDeepLink)
        .onChange(of: deepLinkRouter.pendingTab) {
            showPendingDeepLink()
        }
    }

    private func showPendingDeepLink() {
        guard let tab = deepLinkRouter.consumePendingTab() else {
            return
        }

        selectedTab = tab
        if tab == .apod {
            apodPath = NavigationPath()
            apodLatestRequest += 1
        }
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
        .rootNavigationChrome()
    }
}

private extension View {
    func rootNavigationChrome() -> some View {
        toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

#Preview {
    AppRootView()
        .environmentObject(AppDeepLinkRouter())
}
