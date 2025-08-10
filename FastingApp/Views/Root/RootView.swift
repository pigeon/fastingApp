import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: FastingViewModel
    var body: some View {
        Group {
            if vm.onboarded { HomeShell() } else { OnboardingView() }
        }
    }
}

struct HomeShell: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "largecircle.fill.circle") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
