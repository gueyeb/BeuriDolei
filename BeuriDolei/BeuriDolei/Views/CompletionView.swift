import SwiftUI

struct CompletionView: View {
    let session: PlankSession
    let onDone: () -> Void

    @EnvironmentObject var store: ChallengeStore

    private var totalHeld: Int { session.totalCompleted }
    private var totalTarget: Int { session.totalTarget }
    private var isFullyCompleted: Bool { session.isCompleted }
    private var isRecord: Bool { totalHeld > totalTarget }
    private var nextDay: ChallengeDay? { store.nextDay }

    var body: some View {
        ZStack {
            completionBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                trophy
                messageBlock
                    .padding(.top, 24)
                Spacer()
                stats
                    .padding(.bottom, 18)
                nextDayCard
                Spacer()
                doneButton
                    .padding(.bottom, 48)
            }
        }
        .navigationBarBackButtonHidden()
    }

    // MARK: - Trophy

    private var trophy: some View {
        VStack(spacing: 20) {
            Image(systemName: isFullyCompleted ? "checkmark.seal.fill" : "hand.thumbsup.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(.white)

            Text(isFullyCompleted ? "SÉANCE COMPLÉTÉE" : "BONNE TENTATIVE")
                .font(.title2.weight(.black))
                .tracking(2)
                .foregroundStyle(.white)

            if isRecord {
                Text("RECORD !")
                    .font(.caption.weight(.black))
                    .tracking(2)
                    .foregroundStyle(.yellow)
            } else {
                Text("Jour \(session.dayIndex + 1) sur \(ChallengeDay.totalDays)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var messageBlock: some View {
        VStack(spacing: 10) {
            Text("\(timeString(totalHeld)) / \(timeString(totalTarget))")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(motivationMessage)
                .font(.subheadline.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.82))
                .padding(.horizontal, 32)
        }
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(spacing: 16) {
            statPill(
                value: timeString(totalHeld),
                label: "réalisé"
            )
            statPill(
                value: timeString(totalTarget),
                label: "objectif"
            )
            statPill(
                value: "\(store.streak)",
                label: "jours streak"
            )
        }
        .padding(.horizontal, 24)
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.black).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var nextDayCard: some View {
        if let nextDay {
            VStack(spacing: 6) {
                Text("PROCHAIN JOUR")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.68))
                Text("Jour \(nextDay.dayIndex + 1) · \(timeString(nextDay.totalDuration))")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                Text(nextDay.series.map(timeString).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Done button

    private var doneButton: some View {
        Button(action: onDone) {
            Text("RETOUR À L'ACCUEIL")
                .font(.headline.weight(.black))
                .tracking(1)
                .foregroundStyle(completionBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.white, in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Background

    private var completionBackground: Color {
        isFullyCompleted
            ? Color(red: 0.10, green: 0.67, blue: 0.48)
            : .orange
    }

    // MARK: - Helpers

    private func timeString(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m)'\(s)\""
    }

    private var motivationMessage: String {
        if isRecord {
            return "Vous avez dépassé la cible du jour. Continuez sur ce rythme."
        }
        if isFullyCompleted {
            return "Objectif atteint. Le streak reste propre, revenez demain."
        }
        return "Séance enregistrée. Reposez-vous et reprenez demain."
    }
}

#Preview {
    NavigationStack {
        CompletionView(
            session: PlankSession(
                id: UUID(),
                dayIndex: 0,
                startedAt: Date(),
                endedAt: Date().addingTimeInterval(90),
                seriesCompleted: [25, 22, 20],
                targetSeries: [20, 20, 20]
            ),
            onDone: {}
        )
        .environmentObject(ChallengeStore())
    }
}
