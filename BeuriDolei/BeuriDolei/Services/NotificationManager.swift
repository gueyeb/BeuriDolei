import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let dailyId = "bd.daily"
    private let congratsId = "bd.congrats"

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDailyReminder(at time: Date, dayIndex: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyId])
        let clampedIndex = max(0, min(dayIndex, ChallengeDay.totalDays - 1))
        let day = ChallengeDay.programme[clampedIndex]

        let content = UNMutableNotificationContent()
        content.title = "BeuriDolei"
        content.body = "Jour \(clampedIndex + 1) · objectif \(durationLabel(day.totalDuration)) aujourd'hui."
        content.sound = .default

        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: dailyId, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyId])
    }

    func scheduleCongratsNotification(dayIndex: Int, streak: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [congratsId])

        let content = UNMutableNotificationContent()
        content.title = "Séance complétée ✅"
        content.body = streak > 1
            ? "Jour \(dayIndex + 1) validé · \(streak) jours de suite !"
            : "Jour \(dayIndex + 1) validé · Continue comme ça !"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(identifier: congratsId, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    private func durationLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let minutes = seconds / 60
        let remainder = seconds % 60
        return remainder == 0 ? "\(minutes)min" : "\(minutes)min \(remainder)s"
    }
}
