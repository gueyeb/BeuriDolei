import SwiftUI

@main
struct BeuriDoleiApp: App {
    @StateObject private var store = ChallengeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear {
                    if store.preferences.notificationsEnabled {
                        NotificationManager.shared.requestPermission()
                        NotificationManager.shared.scheduleDailyReminder(
                            at: store.preferences.reminderTime,
                            dayIndex: store.currentDayIndex
                        )
                    }
                }
        }
    }
}
