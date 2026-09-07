import SwiftUI

struct DriftDial: View {
    let drift: Drift
    var side: CGFloat = 96

    var body: some View {
        Shaky { beat in
            ZStack {
                WobblyRect(radius: 6, seed: beat &+ 501, amp: 1.4, step: 10)
                    .stroke(Ink.bone.opacity(0.2), lineWidth: 1.2)

                Path { p in
                    p.move(to: CGPoint(x: side / 2, y: 6))
                    p.addLine(to: CGPoint(x: side / 2, y: side - 6))
                    p.move(to: CGPoint(x: 6, y: side / 2))
                    p.addLine(to: CGPoint(x: side - 6, y: side / 2))
                }
                .stroke(Ink.bone.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))

                WobblyBlob(seed: beat &+ 503, amp: 2)
                    .fill(Ink.flare.opacity(0.34))
                    .overlay(WobblyBlob(seed: beat &+ 503, amp: 2).stroke(Ink.flare, lineWidth: 1.4))
                    .frame(width: max(14, drift.spread * side * 0.9), height: max(14, drift.spread * side * 0.9))
                    .offset(x: drift.dx * side, y: drift.dy * side)
            }
        }
        .frame(width: side, height: side)
    }
}
