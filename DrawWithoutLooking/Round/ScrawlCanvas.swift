
import SwiftUI

struct ScrawlShape: Shape {
    var strokes: [Stroke]
    var reveal: Double = 1

    var animatableData: Double {
        get { reveal }
        set { reveal = newValue }
    }

    private var span: Double {
        strokes.compactMap { $0.dabs.last?.t }.max() ?? 1
    }

    func path(in rect: CGRect) -> Path {
        let cut = span * max(0, min(1, reveal))
        var p = Path()
        for s in strokes {
            var started = false
            for d in s.dabs where d.t <= cut {
                let pt = CGPoint(x: rect.minX + d.x * rect.width, y: rect.minY + d.y * rect.height)
                if started {
                    p.addLine(to: pt)
                } else {
                    p.move(to: pt)
                    started = true
                }
            }
        }
        return p
    }
}

struct ScrawlView: View {
    let strokes: [Stroke]
    var reveal: Double = 1
    var color: Color = Ink.bone
    var weight: CGFloat = 2.7
    var offprint: Bool = true

    var body: some View {
        ZStack {
            if offprint {
                ScrawlShape(strokes: strokes, reveal: reveal)
                    .stroke(Ink.flare.opacity(0.5), style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
                    .offset(x: 2.2, y: -1.6)
                    .blendMode(.plusLighter)
            }
            ScrawlShape(strokes: strokes, reveal: reveal)
                .stroke(color, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup()
    }
}
