import Foundation

struct UserPreferences: Codable {
    var reminderTime: Date?
    var hapticsEnabled: Bool = true
    var graceDayEnabled: Bool = true  // 1 missed day/week doesn't break streak
}
