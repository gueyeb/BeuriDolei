import SwiftUI

struct TimerView: View {
    let day: ChallengeDay
    let variant: PlankVariant
    let onFinish: (() -> Void)?

    @EnvironmentObject var store: ChallengeStore
    @Environment(\.dismiss) private var dismiss

    @State private var timerState: TimerSessionState
    @State private var sessionStartedAt: Date = Date()
    @State private var timer: Timer?
    @State private var showAbandonAlert = false
    @State private var navigateToCompletion = false

    init(day: ChallengeDay, variant: PlankVariant, onFinish: (() -> Void)? = nil) {
        self.day = day
        self.variant = variant
        self.onFinish = onFinish
        _timerState = State(initialValue: TimerSessionState(targetSeries: day.series))
    }

    private var target: Int { timerState.currentTarget }
    private var remaining: Int { timerState.remaining }
    private var ringProgress: Double { timerState.progress }
    private var hasStartedSession: Bool { timerState.hasStartedSession }

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
        .onDisappear {
            timer?.invalidate()
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if timerState.isRunning || timerState.isPaused {
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
            Button("Abandonner", role: .destructive) { abandonSession() }
            Button("Continuer", role: .cancel) {}
        }
        .navigationDestination(isPresented: $navigateToCompletion) {
            CompletionView(
                session: buildSession(),
                onDone: returnToHome
            )
        }
    }

    // MARK: - Series indicator

    private var seriesIndicator: some View {
        HStack(spacing: 10) {
            ForEach(0..<day.series.count, id: \.self) { i in
                Capsule()
                    .fill(pillColor(for: i))
                    .frame(width: i == timerState.currentSerieIndex ? 44 : 28, height: 8)
                    .animation(.spring(duration: 0.3), value: timerState.currentSerieIndex)
            }
        }
    }

    private func pillColor(for index: Int) -> Color {
        if index < timerState.currentSerieIndex { return .white }
        if index == timerState.currentSerieIndex { return .white }
        return .white.opacity(0.3)
    }

    // MARK: - Main timer

    private var mainTimer: some View {
        VStack(spacing: 24) {
            Text(statusLabel)
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
                        .contentTransition(.numericText(countsDown: true))

                    Text("série \(timerState.currentSerieIndex + 1) / \(day.series.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))

                    HStack(spacing: 6) {
                        PlankVariantIcon(variant: variant, isAnimated: timerState.isRunning)
                            .frame(width: 18, height: 18)
                        Text("Planche classique")
                    }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .frame(width: 260, height: 260)
        }
    }

    // MARK: - Bottom bar

    @ViewBuilder
    private var bottomBar: some View {
        if timerState.isRunning || timerState.isPaused {
            HStack(spacing: 16) {
                Button {
                    timerState.isPaused ? resumeTimer() : pauseTimer()
                } label: {
                    Image(systemName: timerState.isPaused ? "play.fill" : "pause.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 60)
                        .background(.white.opacity(0.15), in: Circle())
                }

                Button {
                    stopTimer()
                } label: {
                    Text("STOP")
                        .font(.headline.weight(.black))
                        .tracking(1)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 18))
                }
            }
            .padding(.horizontal, 24)
        } else {
            Button {
                startTimer()
            } label: {
                Text(ctaLabel)
                    .font(.headline.weight(.black))
                    .tracking(1)
                    .foregroundStyle(backgroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 24)
        }
    }

    private var ctaLabel: String {
        hasStartedSession ? "DÉMARRER SÉRIE \(timerState.currentSerieIndex + 1)" : "DÉMARRER"
    }

    private var statusLabel: String {
        if timerState.isRunning { return "EN COURS" }
        if timerState.isPaused { return "PAUSE" }
        if hasStartedSession { return "PRÊT" }
        return "À FAIRE"
    }

    // MARK: - Background color

    private var backgroundColor: Color {
        if ringProgress >= 1.0 {
            return Color(red: 0.10, green: 0.67, blue: 0.48)
        }

        return interpolatedColor(
            from: (0.08, 0.09, 0.11),
            to: (0.94, 0.48, 0.12),
            progress: ringProgress
        )
    }

    // MARK: - Timer logic

    private func startTimer() {
        if timerState.shouldStartNewSession {
            sessionStartedAt = Date()
        }
        timerState.start()
        startTick()
    }

    private func pauseTimer() {
        timerState.pause()
        timer?.invalidate()
    }

    private func resumeTimer() {
        timerState.resume()
        startTick()
    }

    private func startTick() {
        timer?.invalidate()
        let hapticsEnabled = store.preferences.hapticsEnabled
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let result = timerState.tick()
            if hapticsEnabled && timerState.elapsed % 10 == 0 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            if result == .serieCompleted {
                handleSerieCompletion()
            }
        }
    }

    private func handleSerieCompletion() {
        timer?.invalidate()

        if timerState.isComplete {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            store.completeSession(buildSession())
            navigateToCompletion = true
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    private func stopTimer() {
        showAbandonAlert = true
    }

    private func abandonSession() {
        timer?.invalidate()
        timerState.abandon()
        dismiss()
    }

    private func returnToHome() {
        timer?.invalidate()
        navigateToCompletion = false
        DispatchQueue.main.async {
            if let onFinish {
                onFinish()
            } else {
                dismiss()
            }
        }
    }

    private func buildSession() -> PlankSession {
        return PlankSession(
            id: UUID(),
            dayIndex: day.dayIndex,
            variant: variant,
            startedAt: sessionStartedAt,
            endedAt: Date(),
            seriesCompleted: timerState.completedSeriesForSession(),
            targetSeries: day.series
        )
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private func interpolatedColor(
        from start: (Double, Double, Double),
        to end: (Double, Double, Double),
        progress: Double
    ) -> Color {
        let clamped = max(0, min(progress, 1))
        let red = start.0 + (end.0 - start.0) * clamped
        let green = start.1 + (end.1 - start.1) * clamped
        let blue = start.2 + (end.2 - start.2) * clamped
        return Color(red: red, green: green, blue: blue)
    }
}

struct TimerSessionState: Equatable {
    enum TickResult {
        case inProgress
        case serieCompleted
    }

    let targetSeries: [Int]
    private(set) var currentSerieIndex = 0
    private(set) var elapsed = 0
    private(set) var isRunning = false
    private(set) var isPaused = false
    private(set) var seriesCompleted: [Int] = []
    private(set) var isAbandoned = false

    var currentTarget: Int {
        targetSeries[currentSerieIndex]
    }

    var remaining: Int {
        max(currentTarget - elapsed, 0)
    }

    var progress: Double {
        min(Double(elapsed) / Double(currentTarget), 1.0)
    }

    var isLastSerie: Bool {
        currentSerieIndex == targetSeries.count - 1
    }

    var hasStartedCurrentSerie: Bool {
        elapsed > 0 || isRunning || isPaused
    }

    var hasStartedSession: Bool {
        !seriesCompleted.isEmpty || hasStartedCurrentSerie
    }

    var shouldStartNewSession: Bool {
        seriesCompleted.isEmpty && !hasStartedCurrentSerie
    }

    var isComplete: Bool {
        seriesCompleted.count == targetSeries.count
    }

    mutating func start() {
        isRunning = true
        isPaused = false
        isAbandoned = false
    }

    mutating func pause() {
        guard isRunning else { return }
        isRunning = false
        isPaused = true
    }

    mutating func resume() {
        guard isPaused else { return }
        isPaused = false
        isRunning = true
    }

    mutating func tick() -> TickResult {
        guard isRunning, !isComplete else { return .inProgress }

        elapsed += 1
        guard elapsed >= currentTarget else { return .inProgress }

        seriesCompleted.append(min(elapsed, currentTarget))
        isRunning = false
        isPaused = false

        if !isLastSerie {
            currentSerieIndex += 1
            elapsed = 0
        }

        return .serieCompleted
    }

    mutating func abandon() {
        isRunning = false
        isPaused = false
        isAbandoned = true
    }

    func completedSeriesForSession() -> [Int] {
        if seriesCompleted.count == targetSeries.count {
            return seriesCompleted
        }

        return seriesCompleted + Array(
            repeating: 0,
            count: targetSeries.count - seriesCompleted.count
        )
    }
}

#Preview {
    NavigationStack {
        TimerView(day: ChallengeDay.programme[0], variant: .classic)
            .environmentObject(ChallengeStore())
    }
}
