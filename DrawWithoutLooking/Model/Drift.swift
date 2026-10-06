
import CoreGraphics

struct Drift: Codable, Equatable {
    var dx: CGFloat
    var dy: CGFloat
    var spread: CGFloat

    static let centred = Drift(dx: 0, dy: 0, spread: 0.5)

    var offPoints: CGFloat { hypot(dx, dy) * 390 }

    var bearing: String {
        if abs(dx) < 0.02 && abs(dy) < 0.02 { return "dead centre" }
        let ns = dy < -0.02 ? "up" : (dy > 0.02 ? "down" : "")
        let ew = dx < -0.02 ? "left" : (dx > 0.02 ? "right" : "")
        return [ns, ew].filter { !$0.isEmpty }.joined(separator: "-")
    }

    var sizing: String {
        switch spread {
        case ..<0.28: return "cramped"
        case ..<0.55: return "modest"
        case ..<0.8: return "roomy"
        default: return "off the page"
        }
    }
}

enum DriftReader {
    static func measure(_ strokes: [Stroke]) -> Drift? {
        let dabs = strokes.flatMap(\.dabs)
        guard dabs.count > 3 else { return nil }

        var minX = CGFloat.greatestFiniteMagnitude, minY = minX
        var maxX = -CGFloat.greatestFiniteMagnitude, maxY = maxX
        var sx: CGFloat = 0, sy: CGFloat = 0
        for d in dabs {
            minX = min(minX, d.x); maxX = max(maxX, d.x)
            minY = min(minY, d.y); maxY = max(maxY, d.y)
            sx += d.x; sy += d.y
        }
        let n = CGFloat(dabs.count)

        let cx = sx / n, cy = sy / n
        let spread = max(maxX - minX, maxY - minY)
        return Drift(dx: cx - 0.5, dy: cy - 0.5, spread: spread)
    }

    static func rolling(_ scrawls: [Scrawl], seed: Drift?, window: Int = 12) -> Drift {
        let recent = scrawls.sorted { $0.bornAt > $1.bornAt }.prefix(window)
        var samples = recent.compactMap { measure($0.strokes) }
        if let seed, samples.count < 3 { samples.append(seed) }
        guard !samples.isEmpty else { return seed ?? .centred }
        let n = CGFloat(samples.count)
        return Drift(
            dx: samples.reduce(0) { $0 + $1.dx } / n,
            dy: samples.reduce(0) { $0 + $1.dy } / n,
            spread: samples.reduce(0) { $0 + $1.spread } / n
        )
    }

    static func straighten(_ strokes: [Stroke], by drift: Drift) -> [Stroke] {
        let scale = drift.spread > 0.05 ? min(1.9, 0.78 / drift.spread) : 1
        return strokes.map { s in
            Stroke(dabs: s.dabs.map { d in
                Dab(
                    x: (d.x - 0.5 - drift.dx) * scale + 0.5,
                    y: (d.y - 0.5 - drift.dy) * scale + 0.5,
                    t: d.t
                )
            })
        }
    }
}
