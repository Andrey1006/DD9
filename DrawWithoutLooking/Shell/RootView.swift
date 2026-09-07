import SwiftUI

struct RootView: View {
    @EnvironmentObject private var vault: Vault

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            if vault.nib == nil {
                Intake()
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .scale(scale: 1.08).combined(with: .opacity)
                    ))
            } else {
                Deck()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            GrainOverlay()
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: vault.nib == nil)
    }
}
