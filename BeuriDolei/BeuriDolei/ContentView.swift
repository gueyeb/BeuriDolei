import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ChallengeStore

    var body: some View {
        if store.preferences.hasCompletedOnboarding {
            mainTabs
                .onAppear { store.bootstrapPermissionsIfNeeded() }
        } else {
            OnboardingView {
                store.preferences.hasCompletedOnboarding = true
                store.savePreferences()
                store.bootstrapPermissionsIfNeeded()
            }
        }
    }

    private var mainTabs: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("Séance", systemImage: "target") }

            NavigationStack {
                ChallengeProgressView()
            }
            .tabItem { Label("Progression", systemImage: "calendar") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Réglages", systemImage: "gearshape") }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ChallengeStore())
}
