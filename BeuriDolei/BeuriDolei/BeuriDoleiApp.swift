import SwiftUI

@main
struct BeuriDoleiApp: App {
    @StateObject private var store = ChallengeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .onAppear {
                    store.bootstrapPermissionsIfNeeded()
                }
        }
    }
}
