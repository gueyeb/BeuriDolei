import SwiftUI

struct CompletionView: View {
    let session: PlankSession
    let onDone: () -> Void

    @EnvironmentObject var store: ChallengeStore

    private var totalHeld: Int { session.totalCompleted }
    private var isFullyCompleted: Bool { session.isCompleted }

    var body: some View {
        ZStack {
            completionBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                trophy
                Spacer()
                stats
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

            Text("Jour \(session.dayIndex + 1) sur \(ChallengeDay.totalDays)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Stats

    private var stats: some View {
        HStack(spacing: 16) {
            statPill(
                value: timeString(totalHeld),
                label: "temps total"
            )
            statPill(
                value: "\(session.seriesCompleted.count)",
                label: "séries"
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

    // MARK: - Done button

    private var doneButton: some View {
        Button(action: onDone) {
            Text("CONTINUER")
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
            ? .green.mix(with: .teal, by: 0.3)
            : .orange
    }

    // MARK: - Helpers

    private func timeString(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m)'\(s)\""
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
