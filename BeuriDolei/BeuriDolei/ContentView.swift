import SwiftUI

struct ContentView: View {
    var body: some View {
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
