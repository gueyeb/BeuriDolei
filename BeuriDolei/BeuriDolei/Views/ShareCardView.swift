import SwiftUI

struct ShareCardView: View {
    let dayIndex: Int
    let totalHeld: Int
    let totalTarget: Int
    let streak: Int
    let isChallengeDone: Bool
    let date: Date

    private var background: Color {
        isChallengeDone
            ? Color(red: 0.10, green: 0.67, blue: 0.48)
            : .orange
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: isChallengeDone ? "trophy.fill" : "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
                .foregroundStyle(.white)

            Text(isChallengeDone ? "DÉFI TERMINÉ" : "JOUR \(dayIndex + 1) COMPLÉTÉ")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .tracking(1.5)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)

            Text(timeString(totalHeld))
                .font(.system(size: 64, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)

            HStack(spacing: 40) {
                statBlock(value: "\(dayIndex + 1)/30", label: "jour")
                statBlock(value: "\(streak)", label: streak > 1 ? "jours streak" : "jour streak")
            }

            Spacer()

            VStack(spacing: 4) {
                Text("BEURI DOLEI")
                    .font(.headline.weight(.black))
                    .tracking(4)
                    .foregroundStyle(.white)
                Text(date.formatted(
                    Date.FormatStyle(date: .abbreviated, time: .omitted)
                        .locale(Locale(identifier: "fr_FR"))
                ))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.bottom, 8)
        }
        .frame(width: 1080, height: 1350)
        .background(background)
    }

    private func statBlock(value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title.weight(.black).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private func timeString(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        return s == 0 ? "\(m)min" : "\(m)'\(s)\""
    }
}

#Preview {
    ShareCardView(
        dayIndex: 29,
        totalHeld: 900,
        totalTarget: 900,
        streak: 30,
        isChallengeDone: true,
        date: Date()
    )
    .frame(width: 360, height: 450)
}
