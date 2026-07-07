import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var pageIndex = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "flame.fill",
            title: "30 jours, un objectif",
            subtitle: "Une planche par jour, en progression douce de 20 secondes à 5 minutes. Pas de compte, pas de pression, juste vous et le streak."
        ),
        OnboardingPage(
            icon: "timer",
            title: "Un timer simple",
            subtitle: "Démarrez, mettez en pause si besoin, terminez vos séries. Chaque séance complétée fait avancer votre progression."
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            title: "Un rappel, jamais du spam",
            subtitle: "Un rappel quotidien pour ne pas casser le streak. Vous pouvez le désactiver à tout moment dans les réglages."
        ),
    ]

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
                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.orange)
                .frame(width: 120, height: 120)
                .background(.white.opacity(0.08), in: Circle())

            Text(page.title)
                .font(.title.weight(.black))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)

            Text(page.subtitle)
                .font(.body.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.75))
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }

    private var isLastPage: Bool { pageIndex == pages.count - 1 }

    private var ctaButton: some View {
        Button {
            if isLastPage {
                onFinish()
            } else {
                withAnimation { pageIndex += 1 }
            }
        } label: {
            Text(isLastPage ? "COMMENCER" : "SUIVANT")
                .font(.headline.weight(.black))
                .tracking(2)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(.orange, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
}

#Preview {
    OnboardingView(onFinish: {})
}
