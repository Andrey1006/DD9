import Combine
import SwiftUI

struct Blackout: View {
    let seconds: Int
    let word: String
    let trust: Bool
    let sonarOn: Bool
    let onDone: ([Stroke]) -> Void

    @State private var strokes: [Stroke] = []
    @State private var pen: [Dab] = []
    @State private var began = Date()
    @State private var elapsed: Double = 0
    @State private var spent = false
    @StateObject private var sonar = Sonar()

    private let clock = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()

    private var left: Double { max(0, Double(seconds) - elapsed) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Ink.void.ignoresSafeArea()

                if trust {
                    ScrawlView(strokes: live, color: Ink.bone.opacity(0.9), weight: 2.4, offprint: false)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
                }

                VStack {
                    Spacer()
                    Text(String(format: "%.0f", ceil(left)))
                        .font(.placard(64, .light))
                        .foregroundColor(Ink.bone.opacity(left < 4 ? 0.5 : 0.13))
                    Placard(trust ? "keep it turned away" : word, size: 10, color: Ink.bone.opacity(0.16))
                        .padding(.top, 10)
                    Spacer()
                }
                .allowsHitTesting(false)

                Shaky { beat in
                    WobblyRect(radius: 30, seed: beat &+ 401, amp: 1.2, step: 22)
                        .trim(from: 0, to: left / Double(seconds))
                        .stroke(Ink.flare.opacity(left < 4 ? 0.95 : 0.42), lineWidth: left < 4 ? 3.4 : 2)
                }
                .padding(6)
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in ink(v.location, in: geo.size) }
                    .onEnded { _ in liftPen() }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            began = Date()
            Bumper.warm()
            if sonarOn { sonar.open() }
        }
        .onDisappear { sonar.close() }
        .onReceive(clock) { _ in
            guard !spent else { return }
            elapsed = Date().timeIntervalSince(began)
            if elapsed >= Double(seconds) { finish() }
        }
    }

    private var live: [Stroke] {
        pen.count > 1 ? strokes + [Stroke(dabs: pen)] : strokes
    }

    private func ink(_ p: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let nx = p.x / size.width
        let ny = p.y / size.height

        if pen.isEmpty {
            Bumper.lift()
        } else if let last = pen.last, hypot(last.x - nx, last.y - ny) < 0.004 {
            sonar.touch(x: nx, y: ny)
            return
        }

        if nx < 0.045 || nx > 0.955 || ny < 0.035 || ny > 0.965 { Bumper.edge() }

        sonar.touch(x: nx, y: ny)
        pen.append(Dab(x: min(1, max(0, nx)), y: min(1, max(0, ny)), t: Date().timeIntervalSince(began)))
    }

    private func liftPen() {
        sonar.hush()
        guard pen.count > 1 else {
            pen = []
            return
        }
        strokes.append(Stroke(dabs: pen))
        pen = []
    }

    private func finish() {
        spent = true
        liftPen()
        sonar.close()
        Bumper.tap(.rigid)
        onDone(strokes)
    }
}
