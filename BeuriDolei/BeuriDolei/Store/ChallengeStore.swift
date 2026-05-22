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
        // Next uncompleted day, capped at last day
        let completed = Set(sessions.filter(\.isCompleted).map(\.dayIndex))
        let next = (0..<ChallengeDay.totalDays).first { !completed.contains($0) }
        return next ?? ChallengeDay.totalDays - 1
    }

    var currentDay: ChallengeDay {
        ChallengeDay.programme[currentDayIndex]
    }

    var isTodayCompleted: Bool {
        guard let last = sessions.last(where: { $0.dayIndex == currentDayIndex }) else {
            return false
        }
        return last.isCompleted && Calendar.current.isDateInToday(last.endedAt)
    }

    var isChallengeDone: Bool {
        let completed = Set(sessions.filter(\.isCompleted).map(\.dayIndex))
        return completed.count == ChallengeDay.totalDays
    }

    var bestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.endedAt) }
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
        let count = Set(sessions.filter(\.isCompleted).map(\.dayIndex)).count
        return Double(count) / Double(ChallengeDay.totalDays)
    }

    // MARK: - Actions

    func completeSession(_ session: PlankSession) {
        sessions.append(session)
        recalculateStreak()
        save()
    }

    func resetChallenge() {
        sessions = []
        streak = 0
        save()
    }

    // MARK: - Streak calculation

    private func recalculateStreak() {
        let calendar = Calendar.current
        let completedDates = sessions
            .filter(\.isCompleted)
            .map { calendar.startOfDay(for: $0.endedAt) }
            .sorted()

        guard !completedDates.isEmpty else {
            streak = 0
            return
        }

        var count = 0
        var reference = calendar.startOfDay(for: Date())

        // Walk backwards from today
        while true {
            if completedDates.contains(reference) {
                count += 1
                reference = calendar.date(byAdding: .day, value: -1, to: reference)!
            } else if preferences.graceDayEnabled {
                // Allow one missed day per week: skip if next day back is completed
                let dayBefore = calendar.date(byAdding: .day, value: -1, to: reference)!
                if completedDates.contains(dayBefore) {
                    // Check we haven't used grace day in this week already
                    let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
                    let gracesUsed = missedDays(in: completedDates, from: weekAgo, to: Date())
                    if gracesUsed <= 1 {
                        reference = dayBefore
                        continue
                    }
                }
                break
            } else {
                break
            }
        }

        streak = count
    }

    private func missedDays(in dates: [Date], from start: Date, to end: Date) -> Int {
        let calendar = Calendar.current
        var missed = 0
        var current = calendar.startOfDay(for: start)
        let endDay = calendar.startOfDay(for: end)

        while current <= endDay {
            if !dates.contains(current) {
                missed += 1
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return missed
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
