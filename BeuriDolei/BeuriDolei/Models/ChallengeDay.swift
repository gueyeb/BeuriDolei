import Foundation

struct ChallengeDay {
    let dayIndex: Int
    let variant: PlankVariant
    let series: [Int]  // seconds per serie, e.g. [60, 45, 30]

    var totalDuration: Int { series.reduce(0, +) }
    var seriesCount: Int { series.count }

    init(dayIndex: Int, variant: PlankVariant = .classic, series: [Int]) {
        self.dayIndex = dayIndex
        self.variant = variant
        self.series = series
    }
}

// MARK: - 30-day programme
// 3 series per day. Progression: ~20s/serie (J1) → ~5min/serie (J30)
// Total per session: ~1min (J1) → ~15min (J30)
extension ChallengeDay {
    static let programme: [ChallengeDay] = [
        // Week 1 — initiation
        ChallengeDay(dayIndex: 0,  series: [20, 20, 20]),
        ChallengeDay(dayIndex: 1,  series: [25, 20, 20]),
        ChallengeDay(dayIndex: 2,  series: [25, 25, 20]),
        ChallengeDay(dayIndex: 3,  series: [30, 25, 25]),
        ChallengeDay(dayIndex: 4,  series: [30, 30, 25]),
        ChallengeDay(dayIndex: 5,  series: [35, 30, 30]),
        ChallengeDay(dayIndex: 6,  series: [40, 35, 30]),
        // Week 2 — consolidation
        ChallengeDay(dayIndex: 7,  series: [45, 40, 35]),
        ChallengeDay(dayIndex: 8,  series: [50, 45, 40]),
        ChallengeDay(dayIndex: 9,  series: [55, 50, 45]),
        ChallengeDay(dayIndex: 10, series: [60, 55, 50]),
        ChallengeDay(dayIndex: 11, series: [70, 60, 55]),
        ChallengeDay(dayIndex: 12, series: [75, 70, 60]),
        ChallengeDay(dayIndex: 13, series: [80, 75, 65]),
        // Week 3 — progression
        ChallengeDay(dayIndex: 14, series: [90, 80, 70]),
        ChallengeDay(dayIndex: 15, series: [100, 90, 80]),
        ChallengeDay(dayIndex: 16, series: [110, 100, 90]),
        ChallengeDay(dayIndex: 17, series: [120, 110, 100]),
        ChallengeDay(dayIndex: 18, series: [130, 120, 110]),
        ChallengeDay(dayIndex: 19, series: [140, 130, 120]),
        ChallengeDay(dayIndex: 20, series: [150, 140, 130]),
        // Week 4 — performance
        ChallengeDay(dayIndex: 21, series: [165, 150, 140]),
        ChallengeDay(dayIndex: 22, series: [180, 165, 150]),
        ChallengeDay(dayIndex: 23, series: [195, 180, 165]),
        ChallengeDay(dayIndex: 24, series: [210, 195, 180]),
        ChallengeDay(dayIndex: 25, series: [225, 210, 195]),
        ChallengeDay(dayIndex: 26, series: [240, 225, 210]),
        ChallengeDay(dayIndex: 27, series: [255, 240, 225]),
        // Final push — J29 & J30
        ChallengeDay(dayIndex: 28, series: [270, 255, 240]),
        ChallengeDay(dayIndex: 29, series: [300, 270, 255]),
    ]

    static let totalDays = programme.count
}
