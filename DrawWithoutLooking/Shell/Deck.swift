
import SwiftUI

struct Deck: View {
    @EnvironmentObject private var chrome: Chrome

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $chrome.bay) {
                NavigationStack(path: $chrome.wall) {
                    WallTab()
                        .navigationDestination(for: WallRoute.self) { r in
                            switch r {
                            case .exhibit(let id): Exhibit(id: id)
                            }
                        }
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(Bay.wall)

                NavigationStack(path: $chrome.recall) {
                    RecallTab()
                        .navigationDestination(for: RecallRoute.self) { _ in Legibility() }
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(Bay.recall)

                DrawTab()
                    .toolbar(.hidden, for: .tabBar)
                    .tag(Bay.draw)

                NavigationStack(path: $chrome.bout) {
                    BoutTab()
                        .navigationDestination(for: BoutRoute.self) { _ in BoutArchive() }
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(Bay.bout)

                NavigationStack(path: $chrome.you) {
                    YouTab()
                        .navigationDestination(for: YouRoute.self) { _ in Workshop() }
                }
                .toolbar(.hidden, for: .tabBar)
                .tag(Bay.you)
            }

            DeckBar(bay: $chrome.bay)
                .offset(y: chrome.deep ? 150 : 0)
                .opacity(chrome.deep ? 0 : 1)
                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: chrome.deep)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct DeckBar: View {
    @Binding var bay: Bay

    var body: some View {
        HStack(spacing: 0) {
            slot(.wall)
            slot(.recall)
            nibButton
            slot(.bout)
            slot(.you)
        }
        .padding(.horizontal, 10)
        .padding(.top, 11)
        .padding(.bottom, 8)
        .background(
            Shaky { beat in
                WobblyRect(radius: 20, seed: beat &+ 909, amp: 1.6, step: 15)
                    .fill(Ink.soot)
                    .shadow(color: .black.opacity(0.6), radius: 18, y: 8)
            }
        )
        .overlay(
            Shaky { beat in
                WobblyRect(radius: 20, seed: beat &+ 909, amp: 1.6, step: 15)
                    .stroke(Ink.bone.opacity(0.16), lineWidth: 1.2)
            }
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 6)
    }

    private var nibButton: some View {
        Button {
            guard bay != .draw else { return }
            Bumper.tap(.rigid)
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) { bay = .draw }
        } label: {
            Shaky { beat in
                ZStack {
                    WobblyBlob(seed: beat &+ 313, amp: 3)
                        .fill(bay == .draw ? Ink.flare : Ink.smoke)
                    WobblyBlob(seed: beat &+ 317, amp: 3)
                        .stroke(Ink.flare, lineWidth: bay == .draw ? 0 : 1.5)
                    NibGlyph(seed: beat &+ 319)
                        .stroke(bay == .draw ? Ink.base : Ink.flare, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                        .frame(width: 17, height: 24)
                }
            }
            .frame(width: 62, height: 62)
            .offset(y: -16)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func slot(_ b: Bay) -> some View {
        Button {
            guard bay != b else { return }
            Bumper.tap(.light)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { bay = b }
        } label: {
            VStack(spacing: 7) {
                Shaky { beat in
                    glyph(b, beat: beat)
                        .stroke(bay == b ? Ink.bone : Ink.faded.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                        .frame(width: 22, height: 20)
                }
                Placard(b.caption, size: 8, color: bay == b ? Ink.flare : Ink.faded.opacity(0.6), weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func glyph(_ b: Bay, beat: UInt64) -> AnyShape {
        switch b {
        case .wall: return AnyShape(FrameGlyph(seed: beat &+ 1))
        case .recall: return AnyShape(EyeGlyph(seed: beat &+ 2))
        case .bout: return AnyShape(CrowdGlyph(seed: beat &+ 3))
        case .you: return AnyShape(HeadGlyph(seed: beat &+ 4))
        case .draw: return AnyShape(NibGlyph(seed: beat &+ 5))
        }
    }
}
