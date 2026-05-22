import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ChallengeStore
    @State private var navigateToTimer = false
    @State private var navigateToProgress = false
    @State private var showSettings = false

    private var day: ChallengeDay { store.currentDay }
    private var nextDay: ChallengeDay? { store.nextDay }
    private var progress: Double {
        Double(store.currentDayIndex + (store.isTodayCompleted ? 1 : 0)) / Double(ChallengeDay.totalDays)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 0.12, green: 0.08, blue: 0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    progressRing
                    Spacer()
                    objectiveCard
                        .padding(.bottom, 20)
                    seriesCard
                    actionButton
                        .padding(.bottom, 48)
                }
            }
            .navigationDestination(isPresented: $navigateToTimer) {
                TimerView(day: day)
            }
            .navigationDestination(isPresented: $navigateToProgress) {
                ChallengeProgressView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("BEURIDOLEI")
                .font(.caption.weight(.black))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.72))
            Spacer()
            Button { navigateToProgress = true } label: {
                Image(systemName: "calendar")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            streakBadge
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(store.streak)")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white.opacity(0.08), in: Capsule())
    }

    // MARK: - Progress ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: 12)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)

            VStack(spacing: 6) {
                Text("JOUR")
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.72))
                Text("\(store.currentDayIndex + 1)")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("sur \(ChallengeDay.totalDays)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .frame(width: 220, height: 220)
    }

    private var objectiveCard: some View {
        VStack(spacing: 8) {
            Text(store.isTodayCompleted ? "SÉANCE TERMINÉE" : "OBJECTIF DU JOUR")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.65))
            Text(formatted(day.totalDuration))
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text(day.series.map(formatted).joined(separator: " · "))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 24)
    }

    // MARK: - Series card

    private var seriesCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ForEach(Array(day.series.enumerated()), id: \.offset) { index, seconds in
                    VStack(spacing: 4) {
                        Text(formatted(seconds))
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(.white)
                        Text("série \(index + 1)")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)

            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.orange)
                Text("Total · \(formatted(day.totalDuration))")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Action button

    @ViewBuilder
    private var actionButton: some View {
        if store.isTodayCompleted {
            completedState
        } else {
            Button {
                navigateToTimer = true
            } label: {
                Text("COMMENCER")
                    .font(.headline.weight(.black))
                    .tracking(2)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.orange, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(.horizontal, 24)
        }
    }

    private var completedState: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Séance du jour complétée")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Text(completedSubtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private func formatted(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m)min \(s)s"
    }

    private var completedSubtitle: String {
        guard let nextDay else { return "Défi terminé. Bravo." }
        return "Revenez demain pour le jour \(nextDay.dayIndex + 1)"
    }
}

#Preview {
    HomeView()
        .environmentObject(ChallengeStore())
}
