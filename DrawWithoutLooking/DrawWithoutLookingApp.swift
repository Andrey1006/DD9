import SwiftUI

@main
struct DrawWithoutLookingApp: App {
    @StateObject private var vault = Vault.shared
    @StateObject private var chrome = Chrome()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(vault)
                .environmentObject(chrome)
                .preferredColorScheme(.dark)
                .tint(Ink.flare)
                .onAppear { syncRig() }
                .onChange(of: vault.nib) { _ in syncRig() }
                .onChange(of: phase) { p in

                    p == .active ? Tremor.shared.resume() : Tremor.shared.stop()
                }
        }
    }

    private func syncRig() {
        Bumper.on = vault.nib?.haptics ?? true
        Tremor.shared.steady = vault.nib?.steadyHand ?? false
        if !(vault.nib?.steadyHand ?? false) { Tremor.shared.resume() }
    }
}
