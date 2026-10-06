
import SwiftUI

struct Develop: View {
    let strokes: [Stroke]
    let onOpen: () -> Void

    @State private var rubs: [CGPoint] = []
    @State private var touched: Set<Int> = []
    @State private var opened = false

    private let cols = 9
    private let rows = 9
    private let brush: CGFloat = 42

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ScrawlView(strokes: strokes, weight: 3)
                    .frame(width: geo.size.width, height: geo.size.height)

                if !opened {
                    Rectangle()
                        .fill(Ink.void)
                        .overlay(
                            RubMask(points: rubs, brush: brush)
                                .fill(Color.black)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                        .overlay {
                            if rubs.count < 4 {
                                VStack(spacing: 8) {
                                    Shaky { beat in
                                        ArrowGlyph(seed: beat &+ 811)
                                            .stroke(Ink.flare, lineWidth: 1.6)
                                            .frame(width: 44, height: 16)
                                    }
                                    Placard("rub to develop", size: 11, color: Ink.bone.opacity(0.75))
                                }
                                .transition(.opacity)
                            }
                        }
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in smear(v.location, in: geo.size) }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func smear(_ p: CGPoint, in size: CGSize) {
        guard !opened, size.width > 0 else { return }
        if let last = rubs.last, hypot(last.x - p.x, last.y - p.y) < 7 { return }
        rubs.append(p)

        let cx = min(cols - 1, max(0, Int(p.x / size.width * CGFloat(cols))))
        let cy = min(rows - 1, max(0, Int(p.y / size.height * CGFloat(rows))))
        touched.insert(cy * cols + cx)
        if touched.count % 6 == 0 { Bumper.tap(.soft) }

        if Double(touched.count) / Double(cols * rows) > 0.46 {
            opened = true
            Bumper.verdict(true)
            withAnimation(.easeOut(duration: 0.45)) { rubs = [] }
            onOpen()
        }
    }
}

private struct RubMask: Shape {
    let points: [CGPoint]
    let brush: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        for pt in points {
            p.addEllipse(in: CGRect(x: pt.x - brush / 2, y: pt.y - brush / 2, width: brush, height: brush))
        }
        return p
    }
}
