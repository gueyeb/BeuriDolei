import Foundation
import Combine

@MainActor
final class ChallengeStore: ObservableObject {

    // MARK: - Published state
    @Published private(set) var sessions: [PlankSession] = []
    @Published private(set) var streak: Int = 0
    @Published var preferences: UserPreferences = UserPreferences()

    // MARK: - Persistence keys
    private enum Keys {
        static let sessions = "bd_sessions"
        static let preferences = "bd_preferences"
    }

    // MARK: - Init
    init() {
        load()
        recalculateStreak()
    }

    // MARK: - Computed

    var currentDayIndex: Int {
        if let completedToday = todayCompletedSession?.dayIndex {
            return completedToday
        }

        let next = (0..<ChallengeDay.totalDays).first { !completedDayIndexes.contains($0) }
        return next ?? ChallengeDay.totalDays - 1
    }

    var currentDay: ChallengeDay {
        ChallengeDay.programme[currentDayIndex]
    }

    var currentVariant: PlankVariant {
        preferences.preferredVariant
    }

    var isTodayCompleted: Bool {
        todayCompletedSession != nil
    }

    var isChallengeDone: Bool {
        completedDayIndexes.count == ChallengeDay.totalDays
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = Array(Set(sessions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.endedAt) }
        ))
        .sorted()
        guard !sortedDates.isEmpty else { return 0 }
        var best = 1, current = 1
        for i in 1..<sortedDates.count {
            let delta = calendar.dateComponents([.day], from: sortedDates[i-1], to: sortedDates[i]).day ?? 0
            current = delta == 1 ? current + 1 : 1
            best = max(best, current)
        }
        return max(best, streak)
    }

    var totalTimeCompleted: Int {
        sessions.filter(\.isCompleted).reduce(0) { $0 + $1.totalCompleted }
    }

    var completionPercentage: Double {
        Double(completedDayIndexes.count) / Double(ChallengeDay.totalDays)
    }

    var nextDay: ChallengeDay? {
        let nextIndex = currentDayIndex + 1
        guard nextIndex < ChallengeDay.totalDays else { return nil }
        return ChallengeDay.programme[nextIndex]
    }

    var reminderDayIndex: Int {
        if isTodayCompleted, let nextDay {
            return nextDay.dayIndex
        }
        return currentDayIndex
    }

    func streakBroken(since date: Date) -> Bool {
        let calendar = Calendar.current
        let completedDays = completedCalendarDays
        let earliestCompletedDay = completedDays.min()
        let start = calendar.startOfDay(for: date)
        var reference = calendar.startOfDay(for: Date())
        var usedGraceWeeks = Set<Date>()

        while reference >= start {
            if completedDays.contains(reference) {
                reference = calendar.date(byAdding: .day, value: -1, to: reference)!
                continue
            }

            guard preferences.graceDayEnabled,
                  canUseGraceDay(
                    for: reference,
                    completedDays: completedDays,
                    earliestCompletedDay: earliestCompletedDay,
                    usedGraceWeeks: &usedGraceWeeks
                  )
            else {
                return true
            }

            reference = calendar.date(byAdding: .day, value: -1, to: reference)!
        }

        return false
    }

    // MARK: - Actions

    func completeSession(_ session: PlankSession) {
        sessions.append(session)
        recalculateStreak()
        save()
        if preferences.notificationsEnabled {
            NotificationManager.shared.scheduleCongratsNotification(
                dayIndex: session.dayIndex, streak: streak)
            NotificationManager.shared.scheduleDailyReminder(
                at: preferences.reminderTime, dayIndex: reminderDayIndex)
        }
        if preferences.healthKitEnabled {
            HealthKitManager.shared.saveWorkout(session)
        }
    }

    func applyNotificationPreferences() {
        if preferences.notificationsEnabled {
            NotificationManager.shared.scheduleDailyReminder(
                at: preferences.reminderTime, dayIndex: reminderDayIndex)
        } else {
            NotificationManager.shared.cancelDailyReminder()
        }
    }

    func bootstrapPermissionsIfNeeded() {
        bootstrapNotificationPermissionIfNeeded()
        bootstrapHealthKitPermissionIfNeeded()
    }

    func bootstrapNotificationPermissionIfNeeded() {
        guard !preferences.hasRequestedNotificationsPermission else {
            applyNotificationPreferences()
            return
        }

        preferences.hasRequestedNotificationsPermission = true
        save()

        NotificationManager.shared.requestPermission { [weak self] granted in
            guard let self else { return }
            if !granted {
                self.preferences.notificationsEnabled = false
            }
            self.applyNotificationPreferences()
            self.save()
        }
    }

    func bootstrapHealthKitPermissionIfNeeded() {
        guard !preferences.hasRequestedHealthKitPermission else { return }

        preferences.hasRequestedHealthKitPermission = true
        save()

        HealthKitManager.shared.requestPermission { [weak self] granted in
            guard let self else { return }
            self.preferences.healthKitEnabled = granted
            self.save()
        }
    }

    func requestHealthKitPermissionFromSettings() {
        HealthKitManager.shared.requestPermission { [weak self] granted in
            guard let self else { return }
            self.preferences.hasRequestedHealthKitPermission = true
            self.preferences.healthKitEnabled = granted
            self.save()
        }
    }

    func savePreferences() { save() }

    func resetChallenge() {
        sessions = []
        streak = 0
        save()
    }

    // MARK: - Streak calculation

    private func recalculateStreak() {
        let calendar = Calendar.current
        let completedDates = completedCalendarDays
        let earliestCompletedDay = completedDates.min()

        guard !completedDates.isEmpty else {
            streak = 0
            return
        }

        var count = 0
        var reference = calendar.startOfDay(for: Date())
        var usedGraceWeeks = Set<Date>()

        // Walk backwards from today
        while true {
            if completedDates.contains(reference) {
                count += 1
                reference = calendar.date(byAdding: .day, value: -1, to: reference)!
                continue
            }

            guard preferences.graceDayEnabled,
                  canUseGraceDay(
                    for: reference,
                    completedDays: completedDates,
                    earliestCompletedDay: earliestCompletedDay,
                    usedGraceWeeks: &usedGraceWeeks
                  )
            else {
                break
            }

            reference = calendar.date(byAdding: .day, value: -1, to: reference)!
        }

        streak = count
    }

    private func canUseGraceDay(
        for day: Date,
        completedDays: Set<Date>,
        earliestCompletedDay: Date?,
        usedGraceWeeks: inout Set<Date>
    ) -> Bool {
        let calendar = Calendar.current
        guard let earliestCompletedDay else { return false }
        guard day > earliestCompletedDay else { return false }

        let previousDay = calendar.date(byAdding: .day, value: -1, to: day)!
        guard completedDays.contains(previousDay) || day > calendar.startOfDay(for: Date()) else {
            return false
        }

        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: day)?.start else {
            return false
        }

        if usedGraceWeeks.contains(weekStart) {
            return false
        }

        usedGraceWeeks.insert(weekStart)
        return true
    }

    private var todayCompletedSession: PlankSession? {
        sessions.last(where: { $0.isCompleted && Calendar.current.isDateInToday($0.endedAt) })
    }

    private var completedDayIndexes: Set<Int> {
        Set(sessions.filter(\.isCompleted).map(\.dayIndex))
    }

    private var completedCalendarDays: Set<Date> {
        let calendar = Calendar.current
        return Set(sessions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.endedAt) })
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: Keys.sessions)
        }
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: Keys.preferences)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: Keys.sessions),
           let decoded = try? JSONDecoder().decode([PlankSession].self, from: data) {
            sessions = decoded
        }
        if let data = UserDefaults.standard.data(forKey: Keys.preferences),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            preferences = decoded
        }
    }
}
