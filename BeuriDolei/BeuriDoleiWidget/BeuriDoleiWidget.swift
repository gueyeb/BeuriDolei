import WidgetKit
import SwiftUI

struct BeuriDoleiEntry: TimelineEntry {
    let date: Date
    let dayIndex: Int
    let totalDays: Int
    let streak: Int
    let isTodayCompleted: Bool

    static var placeholder: BeuriDoleiEntry {
        BeuriDoleiEntry(date: Date(), dayIndex: 0, totalDays: 30, streak: 0, isTodayCompleted: false)
    }

    static func fromSnapshot() -> BeuriDoleiEntry {
        guard let snapshot = WidgetSnapshot.load() else { return .placeholder }
        return BeuriDoleiEntry(
            date: Date(),
            dayIndex: snapshot.dayIndex,
            totalDays: snapshot.totalDays,
            streak: snapshot.streak,
            isTodayCompleted: snapshot.isTodayCompleted
        )
    }
}

struct BeuriDoleiTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> BeuriDoleiEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BeuriDoleiEntry) -> Void) {
        completion(.fromSnapshot())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BeuriDoleiEntry>) -> Void) {
        let entry = BeuriDoleiEntry.fromSnapshot()
        let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct BeuriDoleiWidgetView: View {
    let entry: BeuriDoleiEntry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.04, blue: 0.02),
                    Color(red: 0.13, green: 0.07, blue: 0.02),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 6) {
                Text("JOUR")
                    .font(.caption2.weight(.bold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.7))

                Text("\(entry.dayIndex + 1)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text("sur \(entry.totalDays)")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 4) {
                    Image(systemName: entry.isTodayCompleted ? "checkmark.circle.fill" : "flame.fill")
                        .foregroundStyle(entry.isTodayCompleted ? .green : .orange)
                        .font(.caption)
                    Text("\(entry.streak) \(entry.streak > 1 ? "jours" : "jour")")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.white.opacity(0.12), in: Capsule())
            }
        }
    }
}

struct BeuriDoleiWidget: Widget {
    let kind = "BeuriDoleiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BeuriDoleiTimelineProvider()) { entry in
            BeuriDoleiWidgetView(entry: entry)
        }
        .configurationDisplayName("BeuriDolei")
        .description("Votre jour et votre streak en un coup d'œil.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    BeuriDoleiWidget()
} timeline: {
    BeuriDoleiEntry.placeholder
    BeuriDoleiEntry(date: Date(), dayIndex: 12, totalDays: 30, streak: 8, isTodayCompleted: true)
}
