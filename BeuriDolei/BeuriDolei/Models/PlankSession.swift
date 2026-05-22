import Foundation

struct PlankSession: Codable, Identifiable {
    let id: UUID
    let dayIndex: Int
    let variant: PlankVariant
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

    private enum CodingKeys: String, CodingKey {
        case id
        case dayIndex
        case variant
        case startedAt
        case endedAt
        case seriesCompleted
        case targetSeries
    }

    init(
        id: UUID,
        dayIndex: Int,
        variant: PlankVariant,
        startedAt: Date,
        endedAt: Date,
        seriesCompleted: [Int],
        targetSeries: [Int]
    ) {
        self.id = id
        self.dayIndex = dayIndex
        self.variant = variant
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.seriesCompleted = seriesCompleted
        self.targetSeries = targetSeries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        dayIndex = try container.decode(Int.self, forKey: .dayIndex)
        variant = try container.decodeIfPresent(PlankVariant.self, forKey: .variant) ?? .classic
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        seriesCompleted = try container.decode([Int].self, forKey: .seriesCompleted)
        targetSeries = try container.decode([Int].self, forKey: .targetSeries)
    }
}
