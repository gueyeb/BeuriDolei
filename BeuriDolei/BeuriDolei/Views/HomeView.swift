import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: ChallengeStore
    @State private var navigateToTimer = false

    private var day: ChallengeDay { store.currentDay }
    private var nextDay: ChallengeDay? { store.nextDay }
    private var selectedVariant: PlankVariant { store.currentVariant }
    private var progress: Double {
        Double(store.currentDayIndex + (store.isTodayCompleted ? 1 : 0)) / Double(ChallengeDay.totalDays)
    }

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
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 48)
                progressRing
                Spacer(minLength: 20)
                objectiveCard
                    .padding(.bottom, 20)
                postureGuide
                    .padding(.bottom, 20)
                seriesCard
                actionButton
                    .padding(.bottom, 32)
            }
        }
        .navigationDestination(isPresented: $navigateToTimer) {
            TimerView(day: day, variant: selectedVariant) {
                navigateToTimer = false
            }
        }
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
                streakBadge
            }
        }
        .frame(width: 220, height: 220)
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("\(store.streak) \(store.streak > 1 ? "jours" : "jour")")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.10), in: Capsule())
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
            HStack(spacing: 6) {
                PlankVariantIcon(variant: selectedVariant)
                    .frame(width: 16, height: 16)
                Text("Planche classique")
            }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 24)
    }

    private var postureGuide: some View {
        HStack(spacing: 16) {
            PlankVariantIcon(variant: .classic, isAnimated: true)
                .frame(width: 72, height: 72)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Position du jour")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.62))
                Text("Planche classique")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)
                Text("Avant-bras au sol, dos droit, corps gainé.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
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
