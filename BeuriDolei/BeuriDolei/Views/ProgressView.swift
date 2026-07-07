import SwiftUI

struct ChallengeProgressView: View {
    @EnvironmentObject var store: ChallengeStore
    @State private var selectedDay: DaySelection?

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
        .sheet(item: $selectedDay) { selection in
            DayDetailSheet(dayIndex: selection.dayIndex)
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
                        selectedDay = DaySelection(dayIndex: dayIndex)
                    }
            }
        }
    }

    private func cellState(for dayIndex: Int) -> DayCellState {
        DayCellStateResolver.state(
            for: dayIndex,
            currentDayIndex: store.currentDayIndex,
            completedDayIndexes: Set(store.sessions.filter(\.isCompleted).map(\.dayIndex))
        )
    }

    // MARK: - Helper

    private func timeLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        return m >= 60 ? "\(m / 60)h\(m % 60 > 0 ? "\(m % 60)m" : "")" : "\(m)min"
    }
}

// MARK: - Cell state

enum DayCellState: Equatable {
    case completed, current, skipped, future
}

struct DayCellStateResolver {
    static func state(
        for dayIndex: Int,
        currentDayIndex: Int,
        completedDayIndexes: Set<Int>
    ) -> DayCellState {
        if completedDayIndexes.contains(dayIndex) { return .completed }
        if dayIndex == currentDayIndex { return .current }
        if dayIndex < currentDayIndex { return .skipped }
        return .future
    }
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

// MARK: - Day selection wrapper

struct DaySelection: Identifiable {
    let dayIndex: Int
    var id: Int { dayIndex }
}

// MARK: - Day detail sheet

struct DayDetailSheet: View {
    let dayIndex: Int
    @EnvironmentObject var store: ChallengeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showInvalidateConfirmation = false

    private var plannedDay: ChallengeDay { ChallengeDay.programme[dayIndex] }
    private var session: PlankSession? {
        store.sessions.last(where: { $0.dayIndex == dayIndex && $0.isCompleted })
    }
    private var isCompleted: Bool { session != nil }
    private var isReachable: Bool { dayIndex <= store.currentDayIndex }

    var body: some View {
        NavigationStack {
            List {
                Section("Prévu") {
                    LabeledContent("Exercice", value: "Planche classique")
                    LabeledContent("Durée totale", value: timeString(plannedDay.totalDuration))
                    ForEach(Array(plannedDay.series.enumerated()), id: \.offset) { index, target in
                        LabeledContent("Série \(index + 1)", value: timeString(target))
                    }
                }

                if let session {
                    Section("Réalisé") {
                        LabeledContent("Date", value: session.endedAt.formatted(
                            Date.FormatStyle(date: .abbreviated, time: .shortened)
                                .locale(Locale(identifier: "fr_FR"))
                        ))
                        LabeledContent("Temps total tenu", value: timeString(session.totalCompleted))
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

                Section {
                    if isCompleted {
                        Button("Invalider ce jour", role: .destructive) {
                            showInvalidateConfirmation = true
                        }
                    } else if isReachable {
                        Button("Valider ce jour") {
                            store.validateDay(dayIndex)
                            dismiss()
                        }
                    } else {
                        Text("Jour à venir — pas encore accessible.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Jour \(dayIndex + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .confirmationDialog(
                "Invalider ce jour ?",
                isPresented: $showInvalidateConfirmation,
                titleVisibility: .visible
            ) {
                Button("Invalider", role: .destructive) {
                    store.invalidateDay(dayIndex)
                    dismiss()
                }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("La séance enregistrée pour le jour \(dayIndex + 1) sera supprimée et le streak sera recalculé.")
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
