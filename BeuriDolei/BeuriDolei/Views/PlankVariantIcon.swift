import SwiftUI

struct PlankVariantIcon: View {
    let variant: PlankVariant
    var isAnimated: Bool = false

    @State private var isBreathing = false

    private let bodyColor = Color(red: 1.00, green: 0.96, blue: 0.90)
    private let accentColor = Color.orange

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)

            ZStack {
                mat(size: size)
                torsoAndLegs(size: size)
                head(size: size)
                forearm(size: size)
                foot(size: size)
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(isAnimated && isBreathing ? 1.03 : 0.98)
            .animation(
                isAnimated ? .easeInOut(duration: 1.4).repeatForever(autoreverses: true) : nil,
                value: isBreathing
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
        .onAppear {
            guard isAnimated else { return }
            isBreathing = true
        }
    }

    private func mat(size: CGFloat) -> some View {
        Capsule()
            .fill(accentColor.opacity(0.42))
            .frame(width: size * 0.70, height: size * 0.055)
            .offset(x: size * 0.08, y: size * 0.32)
    }

    private func torsoAndLegs(size: CGFloat) -> some View {
        Capsule()
            .fill(bodyColor)
            .frame(width: size * 0.62, height: size * 0.16)
            .rotationEffect(.degrees(7))
            .offset(x: size * 0.12, y: -size * 0.04)
    }

    private func head(size: CGFloat) -> some View {
        Circle()
            .fill(bodyColor)
            .frame(width: size * 0.19, height: size * 0.19)
            .offset(x: -size * 0.33, y: -size * 0.10)
    }

    private func forearm(size: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(accentColor)
                .frame(width: size * 0.09, height: size * 0.30)
                .rotationEffect(.degrees(10))
                .offset(x: -size * 0.08, y: size * 0.15)

            Capsule()
                .fill(accentColor)
                .frame(width: size * 0.24, height: size * 0.08)
                .offset(x: -size * 0.03, y: size * 0.29)

            Circle()
                .fill(accentColor)
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(x: -size * 0.14, y: size * 0.28)
        }
    }

    private func foot(size: CGFloat) -> some View {
        Capsule()
            .fill(accentColor)
            .frame(width: size * 0.16, height: size * 0.07)
            .rotationEffect(.degrees(7))
            .offset(x: size * 0.42, y: size * 0.03)
    }
}
