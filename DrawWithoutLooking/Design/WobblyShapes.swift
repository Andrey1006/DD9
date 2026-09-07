import SwiftUI

private func shake(_ pts: [CGPoint], seed: UInt64, amp: CGFloat) -> Path {
    var p = Path()
    guard let head = pts.first else { return p }
    p.move(to: CGPoint(x: head.x + jitter(seed, 0) * amp, y: head.y + jitter(seed, 1) * amp))
    for (i, pt) in pts.enumerated().dropFirst() {
        p.addLine(to: CGPoint(x: pt.x + jitter(seed, i * 2) * amp, y: pt.y + jitter(seed, i * 2 + 1) * amp))
    }
    return p
}

private func walkRounded(_ rect: CGRect, radius: CGFloat, step: CGFloat) -> [CGPoint] {
    let r = max(0, min(radius, min(rect.width, rect.height) / 2))
    var out: [CGPoint] = []

    func straight(_ a: CGPoint, _ b: CGPoint) {
        let len = hypot(b.x - a.x, b.y - a.y)
        let n = max(1, Int(len / step))
        for i in 0..<n {
            let k = CGFloat(i) / CGFloat(n)
            out.append(CGPoint(x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k))
        }
    }

    func corner(_ c: CGPoint, _ from: CGFloat, _ to: CGFloat) {
        guard r > 0.5 else { return }
        let n = max(2, Int((abs(to - from) * r) / step))
        for i in 0...n {
            let a = from + (to - from) * CGFloat(i) / CGFloat(n)
            out.append(CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r))
        }
    }

    let half = CGFloat.pi / 2
    straight(CGPoint(x: rect.minX + r, y: rect.minY), CGPoint(x: rect.maxX - r, y: rect.minY))
    corner(CGPoint(x: rect.maxX - r, y: rect.minY + r), -half, 0)
    straight(CGPoint(x: rect.maxX, y: rect.minY + r), CGPoint(x: rect.maxX, y: rect.maxY - r))
    corner(CGPoint(x: rect.maxX - r, y: rect.maxY - r), 0, half)
    straight(CGPoint(x: rect.maxX - r, y: rect.maxY), CGPoint(x: rect.minX + r, y: rect.maxY))
    corner(CGPoint(x: rect.minX + r, y: rect.maxY - r), half, .pi)
    straight(CGPoint(x: rect.minX, y: rect.maxY - r), CGPoint(x: rect.minX, y: rect.minY + r))
    corner(CGPoint(x: rect.minX + r, y: rect.minY + r), .pi, .pi + half)
    return out
}

struct WobblyRect: Shape {
    var radius: CGFloat = 16
    var seed: UInt64 = 1
    var amp: CGFloat = 1.3
    var step: CGFloat = 11

    func path(in rect: CGRect) -> Path {
        var p = shake(walkRounded(rect.insetBy(dx: amp, dy: amp), radius: radius, step: step), seed: seed, amp: amp)
        p.closeSubpath()
        return p
    }
}

struct WobblyLine: Shape {
    var seed: UInt64 = 1
    var amp: CGFloat = 1.6
    var step: CGFloat = 13

    func path(in rect: CGRect) -> Path {
        let n = max(2, Int(rect.width / step))
        let pts = (0...n).map { i -> CGPoint in
            CGPoint(x: rect.minX + rect.width * CGFloat(i) / CGFloat(n), y: rect.midY)
        }
        return shake(pts, seed: seed, amp: amp)
    }
}

struct WobblyRing: Shape {
    var progress: CGFloat = 1
    var seed: UInt64 = 1
    var amp: CGFloat = 1.4

    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2 - amp
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let sweep = CGFloat.pi * 2 * max(0, min(1, progress))
        let n = max(3, Int(sweep * r / 9))
        let pts = (0...n).map { i -> CGPoint in
            let a = -CGFloat.pi / 2 + sweep * CGFloat(i) / CGFloat(n)
            return CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        }
        return shake(pts, seed: seed, amp: amp)
    }
}

struct WobblyBlob: Shape {
    var seed: UInt64 = 1
    var amp: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        let rx = rect.width / 2 - amp, ry = rect.height / 2 - amp
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let n = 26
        var p = Path()
        for i in 0...n {
            let a = CGFloat(i) / CGFloat(n) * .pi * 2
            let wob = 1 + jitter(seed, i % n) * 0.11
            let pt = CGPoint(x: c.x + cos(a) * rx * wob, y: c.y + sin(a) * ry * wob)
            i == 0 ? p.move(to: pt) : p.addLine(to: pt)
        }
        p.closeSubpath()
        return p
    }
}

struct Tape: Shape {
    var seed: UInt64 = 1

    func path(in rect: CGRect) -> Path {
        let nick = rect.height * 0.22
        let pts = [
            CGPoint(x: rect.minX, y: rect.minY + nick * 0.4),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY - nick * 0.5),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]
        var p = Path()
        p.move(to: CGPoint(x: pts[0].x + jitter(seed, 0), y: pts[0].y + jitter(seed, 1)))
        for (i, pt) in pts.enumerated().dropFirst() {
            p.addLine(to: CGPoint(x: pt.x + jitter(seed, i * 3), y: pt.y + jitter(seed, i * 3 + 1)))
        }
        p.closeSubpath()
        return p
    }
}
