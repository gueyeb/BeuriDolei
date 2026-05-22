import SwiftUI

struct TimerView: View {
    let day: ChallengeDay

    @EnvironmentObject var store: ChallengeStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentSerieIndex = 0
    @State private var elapsed: Int = 0
    @State private var isRunning = false
    @State private var isPaused = false
    @State private var seriesCompleted: [Int] = []
    @State private var sessionStartedAt: Date = Date()
    @State private var timer: Timer?
    @State private var showAbandonAlert = false
    @State private var navigateToCompletion = false

    private var target: Int { day.series[currentSerieIndex] }
    private var remaining: Int { max(target - elapsed, 0) }
    private var ringProgress: Double { min(Double(elapsed) / Double(target), 1.0) }
    private var isLastSerie: Bool { currentSerieIndex == day.series.count - 1 }

    var body: some View {
        ZStack {
            // Background shifts: neutral → orange mid → green on completion
            backgroundColor.ignoresSafeArea()
                .animation(.easeInOut(duration: 0.4), value: ringProgress)

            VStack(spacing: 0) {
                seriesIndicator
                    .padding(.top, 16)

                Spacer()
                mainTimer
                Spacer()

                bottomBar
                    .padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if isRunning || isPaused {
                        showAbandonAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .alert("Abandonner la séance ?", isPresented: $showAbandonAlert) {
            Button("Abandonner", role: .destructive) { dismiss() }
            Button("Continuer", role: .cancel) {}
        }
        .navigationDestination(isPresented: $navigateToCompletion) {
            CompletionView(
                session: buildSession(),
                onDone: { dismiss() }
            )
        }
    }

    // MARK: - Series indicator

    private var seriesIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<day.series.count, id: \.self) { i in
                Capsule()
                    .fill(pillColor(for: i))
                    .frame(width: i == currentSerieIndex ? 44 : 28, height: 8)
                    .animation(.spring(duration: 0.3), value: currentSerieIndex)
            }
        }
    }

    private func pillColor(for index: Int) -> Color {
        if index < currentSerieIndex { return .white }
        if index == currentSerieIndex { return .white }
        return .white.opacity(0.3)
    }

    // MARK: - Main timer

    private var mainTimer: some View {
        VStack(spacing: 24) {
            Text(isRunning || isPaused ? "EN COURS" : "À FAIRE")
                .font(.caption.weight(.bold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.7))

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: ringProgress)

                VStack(spacing: 4) {
                    Text(timeString(remaining))
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)

                    Text("série \(currentSerieIndex + 1) / \(day.series.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 260, height: 260)
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 24) {
            // Pause / Resume
            if isRunning || isPaused {
                Button {
                    isPaused ? resumeTimer() : pauseTimer()
                } label: {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.white.opacity(0.15), in: Circle())
                }
            }

            // Main CTA
            Button {
                if !isRunning && !isPaused {
                    startTimer()
                } else {
                    completeSerie()
                }
            } label: {
                Text(ctaLabel)
                    .font(.headline.weight(.black))
                    .tracking(1)
                    .foregroundStyle(backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .padding(.horizontal, 24)
    }

    private var ctaLabel: String {
        if !isRunning && !isPaused { return "DÉMARRER" }
        if remaining == 0 { return isLastSerie ? "TERMINER" : "SÉRIE SUIVANTE" }
        return isLastSerie ? "TERMINER" : "SÉRIE SUIVANTE"
    }

    // MARK: - Background color

    private var backgroundColor: Color {
        if ringProgress >= 1.0 { return .green.mix(with: .orange, by: 0.3) }
        let intensity = ringProgress
        return Color.orange.mix(with: Color(.systemGroupedBackground), by: 1 - intensity * 0.8)
    }

    // MARK: - Timer logic

    private func startTimer() {
        sessionStartedAt = Date()
        isRunning = true
        isPaused = false
        startTick()
    }

    private func pauseTimer() {
        isPaused = true
        isRunning = false
        timer?.invalidate()
    }

    private func resumeTimer() {
        isPaused = false
        isRunning = true
        startTick()
    }

    private func startTick() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed += 1
            if store.preferences.hapticsEnabled && elapsed % 10 == 0 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    private func completeSerie() {
        timer?.invalidate()
        seriesCompleted.append(elapsed)

        if isLastSerie {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            store.completeSession(buildSession())
            navigateToCompletion = true
        } else {
            // Next serie
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            currentSerieIndex += 1
            elapsed = 0
            isRunning = false
            isPaused = false
        }
    }

    private func buildSession() -> PlankSession {
        let allCompleted = seriesCompleted.count == day.series.count
            ? seriesCompleted
            : seriesCompleted + Array(repeating: 0, count: day.series.count - seriesCompleted.count)
        return PlankSession(
            id: UUID(),
            dayIndex: day.dayIndex,
            startedAt: sessionStartedAt,
            endedAt: Date(),
            seriesCompleted: allCompleted,
            targetSeries: day.series
        )
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

#Preview {
    NavigationStack {
        TimerView(day: ChallengeDay.programme[0])
            .environmentObject(ChallengeStore())
    }
}
