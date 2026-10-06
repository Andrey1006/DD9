
import SwiftUI

struct BackNail: ToolbarContent {
    let title: String
    let back: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                Bumper.tap(.light)
                back()
            } label: {
                HStack(spacing: 8) {
                    Shaky { beat in
                        ArrowGlyph(seed: beat &+ 601)
                            .stroke(Ink.flare, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                            .rotationEffect(.degrees(180))
                            .frame(width: 18, height: 12)
                    }
                    Placard(title, size: 10, color: Ink.bone, weight: .semibold)
                }
            }
        }
    }
}

extension View {
    func pushedScreen(_ title: String, back: @escaping () -> Void) -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar(.hidden, for: .tabBar)
            .toolbar { BackNail(title: title, back: back) }
    }
}
