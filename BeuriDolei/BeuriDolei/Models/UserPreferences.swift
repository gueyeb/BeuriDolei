import Foundation

struct UserPreferences: Codable, Equatable {
    var notificationsEnabled: Bool = true
    var reminderTime: Date = {
        var c = DateComponents()
        c.hour = 8
        c.minute = 0
        return Calendar.current.date(from: c) ?? Date()
    }()
    var hapticsEnabled: Bool = true
    var graceDayEnabled: Bool = true
    var healthKitEnabled: Bool = false
    var preferredVariant: PlankVariant = .classic
    var hasRequestedNotificationsPermission: Bool = false
    var hasRequestedHealthKitPermission: Bool = false

    private enum CodingKeys: String, CodingKey {
        case notificationsEnabled
        case reminderTime
        case hapticsEnabled
        case graceDayEnabled
        case healthKitEnabled
        case preferredVariant
        case hasRequestedNotificationsPermission
        case hasRequestedHealthKitPermission
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime) ?? {
            var c = DateComponents()
            c.hour = 8
            c.minute = 0
            return Calendar.current.date(from: c) ?? Date()
        }()
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        graceDayEnabled = try container.decodeIfPresent(Bool.self, forKey: .graceDayEnabled) ?? true
        healthKitEnabled = try container.decodeIfPresent(Bool.self, forKey: .healthKitEnabled) ?? false
        preferredVariant = try container.decodeIfPresent(PlankVariant.self, forKey: .preferredVariant) ?? .classic
        hasRequestedNotificationsPermission = try container.decodeIfPresent(Bool.self, forKey: .hasRequestedNotificationsPermission) ?? false
        hasRequestedHealthKitPermission = try container.decodeIfPresent(Bool.self, forKey: .hasRequestedHealthKitPermission) ?? false
    }
}
