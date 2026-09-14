import SwiftUI

private struct ScrawlTrail: Shape {
    var seed: UInt64
    var wobble: CGFloat = 3.2

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let cx = rect.midX
        let cy = rect.midY
        let rx = rect.width * 0.34
        let ry = rect.height * 0.34
        let steps = 260

        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let a = t * .pi * 2
            let swell = 0.55 + 0.45 * sin(a * 3 + 0.6)
            let x = cx + cos(a * 2 + 0.4) * rx * swell + jitter(seed, i) * wobble
            let y = cy + sin(a * 3) * ry * swell + jitter(seed &+ 77, i) * wobble
            i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
        }
        return p
    }
}

private struct Halo: View {
    var progress: Double
    var delay: Double

    private var k: Double { max(0, min(1, (progress - delay) / 0.42)) }

    var body: some View {
        Circle()
            .stroke(Ink.flare.opacity(0.7 * (1 - k)), lineWidth: 2.2 * (1 - k) + 0.4)
            .scaleEffect(0.18 + k * 1.5)
            .opacity(k > 0 ? 1 : 0)
    }
}

struct SplashView: View {
    var onFinished: () -> Void = {}
    var autoDismiss: Bool = true

    @State private var draw: CGFloat = 0
    @State private var erase: CGFloat = 0
    @State private var blind: CGFloat = -1.4
    @State private var pulse: Double = 0
    @State private var glow: Double = 0
    @State private var lift: Double = 0
    @State private var word: Double = 0
    @State private var fadeOut = false

    private let duration: TimeInterval = 3

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            RadialGradient(
                colors: [Ink.smoke.opacity(0.85 * glow), Ink.base.opacity(0)],
                center: .center,
                startRadius: 4,
                endRadius: 320
            )
            .ignoresSafeArea()

            Shaky { beat in
                ZStack {
                    ScrawlTrail(seed: beat)
                        .trim(from: erase, to: draw)
                        .stroke(
                            Ink.flare.opacity(0.55),
                            style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
                        )
                        .blur(radius: 9)
                        .offset(x: 2.5, y: -2)

                    ScrawlTrail(seed: beat)
                        .trim(from: erase, to: draw)
                        .stroke(
                            Ink.bone,
                            style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round)
                        )

                    ScrawlTrail(seed: beat &+ 0x51)
                        .trim(from: max(erase, draw - 0.02), to: draw)
                        .stroke(Ink.cobalt, style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
                        .blur(radius: 1.6)
                }
                .frame(width: 230, height: 230)
            }
            .scaleEffect(1 + lift * 0.06)

            ZStack {
                Halo(progress: pulse, delay: 0)
                Halo(progress: pulse, delay: 0.16)
                Halo(progress: pulse, delay: 0.32)
            }
            .frame(width: 230, height: 230)

            Circle()
                .fill(Ink.flare)
                .frame(width: 10, height: 10)
                .scaleEffect(0.4 + pulse * 1.1)
                .opacity(glow)
                .shadow(color: Ink.flare.opacity(0.9), radius: 16)

            GeometryReader { geo in
                Capsule()
                    .fill(Ink.soot)
                    .frame(width: geo.size.width * 1.6, height: 74)
                    .overlay(
                        Capsule().stroke(Ink.smoke, lineWidth: 1)
                    )
                    .rotationEffect(.degrees(-7))
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .offset(x: geo.size.width * blind)
                    .shadow(color: Ink.void.opacity(0.6), radius: 18, y: 6)
            }
            .allowsHitTesting(false)
            .ignoresSafeArea()

            VStack(spacing: 14) {
                Spacer()
                Placard("EYES SHUT", size: 13, color: Ink.bone, weight: .semibold)
                    .opacity(word)
                    .offset(y: (1 - word) * 14)

                Placard("HANDS LOOSE", size: 10, color: Ink.faded)
                    .opacity(word * 0.9)
                    .offset(y: (1 - word) * 22)
                Spacer().frame(height: 72)
            }

            GrainOverlay(strength: 0.11)
        }
        .opacity(fadeOut ? 0 : 1)
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        withAnimation(.easeOut(duration: 0.5)) { glow = 1 }
        withAnimation(.easeInOut(duration: 1.45)) { draw = 1 }
        withAnimation(.easeOut(duration: 0.7).delay(0.35)) { lift = 1 }
        withAnimation(.easeIn(duration: 0.55).delay(1.35)) { blind = 0 }
        withAnimation(.easeOut(duration: 0.6).delay(1.55)) { word = 1 }
        withAnimation(.easeIn(duration: 0.5).delay(1.75)) { blind = 1.4 }
        withAnimation(.linear(duration: 1.6).delay(1.4).repeatForever(autoreverses: false)) { pulse = 1 }

        guard autoDismiss else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration - 1.3) {
            withAnimation(.easeInOut(duration: 0.75)) { erase = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration - 0.5) {
            withAnimation(.easeIn(duration: 0.5)) { fadeOut = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onFinished()
        }
    }
}

#Preview {
    SplashView()
        .preferredColorScheme(.dark)
}
