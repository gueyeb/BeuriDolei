import Foundation

struct UserPreferences: Codable, Equatable {
    var notificationsEnabled: Bool = true
    var reminderTime: Date = {
        var c = DateComponents(); c.hour = 8; c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    var hapticsEnabled: Bool = true
    var graceDayEnabled: Bool = true
    var healthKitEnabled: Bool = false
}
