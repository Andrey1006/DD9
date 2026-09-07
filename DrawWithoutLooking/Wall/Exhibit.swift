import SwiftUI

struct Exhibit: View {
    let id: UUID

    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    @State private var reveal: Double = 1
    @State private var straight = false
    @State private var doomed = false

    private var s: Scrawl? { vault.scrawl(id) }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            if let s {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        frame(s)
                        placard(s)
                        controls(s)
                        history(s)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 60)
                }
            } else {
                EmptyFrame(headline: "Gone", note: "This exhibit was taken off the wall.")
            }
        }
        .pushedScreen("Wall") { chrome.wall.removeLast() }
        .alert("Take it off the wall?", isPresented: $doomed) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                vault.toss(id)
                chrome.wall.removeAll()
            }
        } message: {
            Text("This drawing and its recall record are deleted for good.")
        }
    }

    private func frame(_ s: Scrawl) -> some View {
        Scrap(tilt: lean(s.id, range: 1.4), fill: Ink.void, edge: Ink.bone.opacity(0.28), seed: UInt64(abs(s.id.hashValue % 900)), taped: true) {
            ScrawlView(
                strokes: straight ? DriftReader.straighten(s.strokes, by: vault.drift) : s.strokes,
                reveal: reveal,
                weight: 3.2
            )
            .padding(14)
        }
        .padding(.top, 6)
    }

    private func placard(_ s: Scrawl) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(s.word.uppercased())
                .font(.slug(34)).tracking(-1.4).foregroundColor(Ink.bone)
                .overprint(s.pack.stamp, dx: 2.6, dy: -2, opacity: 0.4)

            HStack(spacing: 7) {
                Placard(s.pack.title, size: 9, color: s.pack.stamp)
                Placard("·", size: 9)
                Placard("\(s.seconds)s", size: 9)
                Placard("·", size: 9)
                Placard("\(s.strokes.count) strokes", size: 9)
                if let b = s.bet {
                    Placard("·", size: 9)
                    Placard("called \(b.call)", size: 9)
                }
            }
            Placard(stamp(s), size: 9, color: Ink.faded.opacity(0.8))
        }
    }

    private func stamp(_ s: Scrawl) -> String {
        let when = s.bornAt.formatted(date: .abbreviated, time: .shortened)
        switch s.origin {
        case .calibration: return "calibration round · \(when)"
        case .bout: return "bout · by \(s.artist ?? "someone") · \(when)"
        case .solo: return "solo · \(when)"
        }
    }

    private func controls(_ s: Scrawl) -> some View {
        VStack(spacing: 10) {
            Button("Play it back") {
                Bumper.tap(.soft)
                reveal = 0
                withAnimation(.linear(duration: max(1.1, Double(s.seconds) * 0.55))) { reveal = 1 }
            }
            .buttonStyle(SlabButtonStyle(tint: Ink.flare, seed: 311, tall: 52))

            Button(straight ? "Back to raw" : "Straighten by my drift") {
                Bumper.tap(.light)
                withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { straight.toggle() }
            }
            .buttonStyle(GhostButtonStyle(tint: Ink.cobalt, seed: 313, tall: 46))

            HStack(spacing: 10) {
                Button(s.pinned ? "Unpin" : "Pin it") {
                    Bumper.tap(.light)
                    vault.flip(id)
                }
                .buttonStyle(GhostButtonStyle(tint: s.pinned ? Ink.flare : Ink.bone, seed: 315, tall: 46))

                Button("Remove") { doomed = true }
                    .buttonStyle(GhostButtonStyle(tint: Ink.faded, seed: 317, tall: 46))
            }
        }
    }

    @ViewBuilder
    private func history(_ s: Scrawl) -> some View {
        if s.recalls.isEmpty {
            Scrap(tilt: -0.8, seed: 321) {
                VStack(alignment: .leading, spacing: 6) {
                    Placard("not tested yet", size: 9, color: Ink.cobalt)
                    Text("Recall has not shown you this one. When it does, you will find out whether your own drawing means anything to you.")
                        .font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(3)
                }
                .padding(16)
            }
        } else {
            Scrap(tilt: -0.8, seed: 321) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Placard("recall record", size: 9, color: Ink.cobalt)
                        Spacer()
                        Placard("\(Int((s.legibility ?? 0) * 100))% read", size: 9, color: s.unreadable ? Ink.flare : Ink.bone)
                    }
                    ForEach(Array(s.recalls.enumerated()), id: \.offset) { _, r in
                        HStack(spacing: 10) {
                            Shaky { beat in
                                Group {
                                    if r.hit {
                                        TickGlyph(seed: beat).stroke(Ink.cobalt, style: StrokeStyle(lineWidth: 1.8, lineJoin: .round))
                                    } else {
                                        CrossGlyph(seed: beat).stroke(Ink.flare, lineWidth: 1.6)
                                    }
                                }
                                .frame(width: 14, height: 13)
                            }
                            Text(r.guessed.uppercased()).placardStyle(11, r.hit ? Ink.bone : Ink.faded)
                            Spacer(minLength: 0)
                            Placard(DayKey.string(r.at), size: 8)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}
