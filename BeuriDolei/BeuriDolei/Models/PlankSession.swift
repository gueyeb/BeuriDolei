import Foundation

struct PlankSession: Codable, Identifiable {
    let id: UUID
    let dayIndex: Int
    let startedAt: Date
    let endedAt: Date
    let seriesCompleted: [Int]  // actual seconds held per serie
    let targetSeries: [Int]     // target seconds per serie

    var isCompleted: Bool {
        guard seriesCompleted.count == targetSeries.count else { return false }
        return zip(seriesCompleted, targetSeries).allSatisfy { actual, target in
            actual >= target
        }
    }

    var totalCompleted: Int { seriesCompleted.reduce(0, +) }
    var totalTarget: Int { targetSeries.reduce(0, +) }
    var duration: TimeInterval { endedAt.timeIntervalSince(startedAt) }
}
