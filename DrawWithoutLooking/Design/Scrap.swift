
import SwiftUI

struct Scrap<Content: View>: View {
    var tilt: Double = 0
    var fill: Color = Ink.soot
    var edge: Color = Ink.bone.opacity(0.28)
    var radius: CGFloat = 13
    var seed: UInt64 = 3
    var taped: Bool = false
    var lineWidth: CGFloat = 1.4
    @ViewBuilder var content: () -> Content

    @ViewBuilder
    private func corner(_ angle: Double, x: CGFloat, dodge: UInt64) -> some View {
        if taped {
            Shaky { beat in
                Tape(seed: beat &+ seed &+ 99 &+ dodge)
                    .fill(Ink.bone.opacity(0.17))
                    .overlay(Tape(seed: beat &+ seed &+ 99 &+ dodge).stroke(Ink.bone.opacity(0.1), lineWidth: 0.8))
                    .frame(width: 52, height: 15)
                    .rotationEffect(.degrees(angle))
                    .offset(x: x, y: -7)
            }
        }
    }

    var body: some View {
        content()
            .background(
                Shaky { beat in
                    WobblyRect(radius: radius, seed: beat &+ seed, amp: 1.5)
                        .fill(fill)
                }
            )
            .overlay(
                Shaky { beat in
                    WobblyRect(radius: radius, seed: beat &+ seed, amp: 1.5)
                        .stroke(edge, lineWidth: lineWidth)
                }
            )
            .overlay(alignment: .topLeading) { corner(-40, x: -13, dodge: 0) }
            .overlay(alignment: .topTrailing) { corner(38, x: 13, dodge: 17) }
            .rotationEffect(.degrees(tilt))
    }
}

extension View {
    func hairline(_ color: Color = Ink.bone.opacity(0.16), seed: UInt64 = 5) -> some View {
        overlay(alignment: .bottom) {
            Shaky { beat in
                WobblyLine(seed: beat &+ seed).stroke(color, lineWidth: 1.2).frame(height: 4)
            }
        }
    }
}

func lean(_ id: UUID, range: Double = 2.6) -> Double {
    let h = UInt64(abs(id.uuidString.hashValue % 1000))
    return (Double(h) / 1000.0 - 0.5) * 2 * range
}
