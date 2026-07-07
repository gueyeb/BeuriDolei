import Foundation

/// Minimal state mirrored into the shared App Group container so the
/// widget extension can render the current day/streak without relying
/// on the main app's full ChallengeStore.
struct WidgetSnapshot: Codable {
    static let appGroupID = "group.com.dakhine.BeuriDolei"
    static let userDefaultsKey = "bd_widget_snapshot"

    let dayIndex: Int
    let totalDays: Int
    let streak: Int
    let isTodayCompleted: Bool
    let updatedAt: Date

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.sharedDefaults?.set(data, forKey: Self.userDefaultsKey)
    }

    static func load() -> WidgetSnapshot? {
        guard let data = sharedDefaults?.data(forKey: userDefaultsKey),
              let decoded = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return nil }
        return decoded
    }
}
