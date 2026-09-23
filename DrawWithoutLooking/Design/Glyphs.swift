import SwiftUI

struct FrameGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = WobblyRect(radius: 2, seed: seed, amp: 1.1, step: 7).path(in: r)
        p.move(to: CGPoint(x: r.minX + r.width * 0.22, y: r.maxY - r.height * 0.24))
        p.addLine(to: CGPoint(x: r.midX + jitter(seed, 3), y: r.minY + r.height * 0.42))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.18, y: r.maxY - r.height * 0.24))
        return p
    }
}

struct EyeGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 22
        for i in 0...n {
            let k = CGFloat(i) / CGFloat(n)
            let x = r.minX + r.width * k
            let lid = sin(k * .pi) * r.height * 0.44
            let pt = CGPoint(x: x, y: r.midY - lid + jitter(seed, i))
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        for i in stride(from: n, through: 0, by: -1) {
            let k = CGFloat(i) / CGFloat(n)
            let lid = sin(k * .pi) * r.height * 0.44
            p.addLine(to: CGPoint(x: r.minX + r.width * k, y: r.midY + lid + jitter(seed, i + 40)))
        }
        p.closeSubpath()
        p.addPath(WobblyBlob(seed: seed &+ 7, amp: 1).path(in: CGRect(x: r.midX - r.width * 0.13, y: r.midY - r.width * 0.13, width: r.width * 0.26, height: r.width * 0.26)))
        return p
    }
}

struct NibGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        let pts = [
            CGPoint(x: r.midX, y: r.maxY),
            CGPoint(x: r.minX + r.width * 0.16, y: r.minY + r.height * 0.34),
            CGPoint(x: r.midX - r.width * 0.1, y: r.minY),
            CGPoint(x: r.midX + r.width * 0.1, y: r.minY),
            CGPoint(x: r.maxX - r.width * 0.16, y: r.minY + r.height * 0.34)
        ]
        var p = Path()
        p.move(to: CGPoint(x: pts[0].x + jitter(seed, 0), y: pts[0].y))
        for (i, pt) in pts.enumerated().dropFirst() {
            p.addLine(to: CGPoint(x: pt.x + jitter(seed, i), y: pt.y + jitter(seed, i + 10)))
        }
        p.closeSubpath()
        p.move(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.16))
        p.addLine(to: CGPoint(x: r.midX + jitter(seed, 21) * 1.5, y: r.minY + r.height * 0.3))
        return p
    }
}

struct CrowdGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = Path()
        let d = r.width * 0.42
        for (i, cx) in [r.minX + d * 0.55, r.maxX - d * 0.55].enumerated() {
            let head = CGRect(x: cx - d * 0.34, y: r.minY + CGFloat(i) * 2, width: d * 0.68, height: d * 0.68)
            p.addPath(WobblyBlob(seed: seed &+ UInt64(i * 13), amp: 1.2).path(in: head))
            let body = CGRect(x: cx - d * 0.52, y: head.maxY + 1, width: d * 1.04, height: r.maxY - head.maxY - 1)
            p.addPath(WobblyRect(radius: d * 0.4, seed: seed &+ UInt64(i * 29), amp: 1.2, step: 6).path(in: body))
        }
        return p
    }
}

struct HeadGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = WobblyBlob(seed: seed, amp: 1.4).path(in: CGRect(x: r.midX - r.width * 0.27, y: r.minY, width: r.width * 0.54, height: r.width * 0.54))
        let n = 16
        for i in 0...n {
            let k = CGFloat(i) / CGFloat(n)
            let a = CGFloat.pi + k * .pi
            let pt = CGPoint(x: r.midX + cos(a) * r.width * 0.46, y: r.maxY - sin(a) * r.height * 0.34 - r.height * 0.34)
            i == 0 ? p.move(to: pt) : p.addLine(to: CGPoint(x: pt.x + jitter(seed, i), y: pt.y + jitter(seed, i + 60)))
        }
        return p
    }
}

struct CrossGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + jitter(seed, 1), y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX + jitter(seed, 2), y: r.maxY + jitter(seed, 3)))
        p.move(to: CGPoint(x: r.maxX + jitter(seed, 4), y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + jitter(seed, 5), y: r.maxY + jitter(seed, 6)))
        return p
    }
}

struct ArrowGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + jitter(seed, 1)))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY + jitter(seed, 2)))
        p.move(to: CGPoint(x: r.maxX - r.width * 0.34, y: r.minY + jitter(seed, 3)))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.34, y: r.maxY + jitter(seed, 4)))
        return p
    }
}

struct TickGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY + jitter(seed, 1)))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.36, y: r.maxY + jitter(seed, 2)))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + jitter(seed, 3)))
        return p
    }
}

struct LensGlyph: Shape {
    var seed: UInt64 = 1
    func path(in r: CGRect) -> Path {
        let side = min(r.width, r.height) * 0.74
        var p = WobblyBlob(seed: seed, amp: 1.1).path(in: CGRect(x: r.minX, y: r.minY, width: side, height: side))
        p.move(to: CGPoint(x: r.minX + side * 0.8 + jitter(seed, 1), y: r.minY + side * 0.8 + jitter(seed, 2)))
        p.addLine(to: CGPoint(x: r.maxX + jitter(seed, 3), y: r.maxY + jitter(seed, 4)))
        return p
    }
}
