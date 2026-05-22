import SwiftUI

struct ChallengeProgressView: View {
    @EnvironmentObject var store: ChallengeStore
    @State private var selectedSession: PlankSession?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                statsRow
                    .padding(.top, 8)
                grid
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Progression")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedSession) { session in
            SessionDetailSheet(session: session)
        }
    }

    // MARK: - Stats row

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(value: "\(store.bestStreak)", label: "meilleur\nstreak", icon: "flame.fill", color: .orange)
            statCard(value: timeLabel(store.totalTimeCompleted), label: "temps\ntotal", icon: "timer", color: .blue)
            statCard(value: "\(Int(store.completionPercentage * 100))%", label: "jours\ncomplétés", icon: "checkmark.circle.fill", color: .green)
        }
    }

    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.subheadline)
            Text(value)
                .font(.title3.weight(.black).monospacedDigit())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 30-day grid

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(0..<ChallengeDay.totalDays, id: \.self) { dayIndex in
                DayCellView(dayIndex: dayIndex, state: cellState(for: dayIndex))
                    .onTapGesture {
                        if let session = store.sessions.last(where: { $0.dayIndex == dayIndex && $0.isCompleted }) {
                            selectedSession = session
                        }
                    }
            }
        }
    }

    private func cellState(for dayIndex: Int) -> DayCellState {
        let completedDays = Set(store.sessions.filter(\.isCompleted).map(\.dayIndex))
        if completedDays.contains(dayIndex) { return .completed }
        if dayIndex == store.currentDayIndex { return .current }
        if dayIndex < store.currentDayIndex { return .skipped }
        return .future
    }

    // MARK: - Helper

    private func timeLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        return m >= 60 ? "\(m / 60)h\(m % 60 > 0 ? "\(m % 60)m" : "")" : "\(m)min"
    }
}

// MARK: - Cell state

enum DayCellState {
    case completed, current, skipped, future
}

// MARK: - Day cell

struct DayCellView: View {
    let dayIndex: Int
    let state: DayCellState

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(state == .current ? Color.orange : .clear, lineWidth: 2)
                )

            switch state {
            case .completed:
                VStack(spacing: 1) {
                    Text("\(dayIndex + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                }
            case .skipped:
                VStack(spacing: 1) {
                    Text("\(dayIndex + 1)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            default:
                Text("\(dayIndex + 1)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(state == .current ? .orange : .secondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var backgroundColor: Color {
        switch state {
        case .completed: return .green
        case .current:   return Color.orange.opacity(0.12)
        case .skipped:   return Color(.systemFill)
        case .future:    return Color(.secondarySystemGroupedBackground)
        }
    }
}

// MARK: - Session detail sheet

struct SessionDetailSheet: View {
    let session: PlankSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Jour \(session.dayIndex + 1)") {
                    LabeledContent("Date", value: session.endedAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Durée séance", value: timeString(Int(session.duration)))
                    LabeledContent("Temps total tenu", value: timeString(session.totalCompleted))
                }
                Section("Séries") {
                    ForEach(Array(zip(session.seriesCompleted, session.targetSeries).enumerated()), id: \.offset) { index, pair in
                        let (actual, target) = pair
                        LabeledContent("Série \(index + 1)") {
                            HStack(spacing: 4) {
                                Text(timeString(actual))
                                    .fontWeight(.semibold)
                                    .foregroundStyle(actual >= target ? .green : .orange)
                                Text("/ \(timeString(target))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Détails séance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60, s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m)min \(s)s"
    }
}

#Preview {
    NavigationStack {
        ChallengeProgressView()
            .environmentObject(ChallengeStore())
    }
}
