import SwiftUI

enum Grain {
    static let tile: UIImage = {
        let side = 96
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: fmt).image { ctx in
            var rng = Seeded(0xC0FFEE)
            for y in 0..<side {
                for x in 0..<side {
                    let v = CGFloat(rng.next(0..<255)) / 255
                    ctx.cgContext.setFillColor(gray: v, alpha: 1)
                    ctx.cgContext.fill(CGRect(x: x, y: y, width: 1, height: 1))
                }
            }
        }
    }()
}

struct GrainOverlay: View {
    var strength: Double = 0.085

    var body: some View {
        Image(uiImage: Grain.tile)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(strength)
            .allowsHitTesting(false)
            .ignoresSafeArea()
    }
}

extension View {

    func overprint(_ tint: Color = Ink.flare, dx: CGFloat = 2, dy: CGFloat = -1.5, opacity: Double = 0.55) -> some View {
        ZStack {
            self
                .overlay(tint)
                .mask(self)
                .offset(x: dx, y: dy)
                .opacity(opacity)
            self
        }
    }
}
