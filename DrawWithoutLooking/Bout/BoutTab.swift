import SwiftUI

struct BoutTab: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    private enum Leg { case lobby, handoff, draw, guessing, board }

    @State private var leg: Leg = .lobby
    @State private var roster: [Player] = []
    @State private var draft = ""
    @State private var pack: Pack = .animals
    @State private var laps = 2

    @State private var round = 0
    @State private var word = ""
    @State private var peeking = false
    @State private var strokes: [Stroke] = []
    @State private var options: [String] = []
    @State private var madeIt: Bool?
    @State private var spoils: [Scrawl] = []

    private var artist: Player? { roster.isEmpty ? nil : roster[round % roster.count] }
    private var guesser: Player? { roster.isEmpty ? nil : roster[(round + 1) % roster.count] }
    private var total: Int { roster.count * laps }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            switch leg {
            case .lobby: lobby.transition(.opacity)
            case .handoff: handoff.transition(.scale(scale: 0.95).combined(with: .opacity))
            case .draw:
                Blackout(seconds: vault.nib?.seconds ?? 15, word: word, trust: false, sonarOn: vault.nib?.sonar ?? true) { s in
                    strokes = s
                    hop(.guessing)
                }
                .transition(.opacity)
            case .guessing: guessing.transition(.move(edge: .trailing).combined(with: .opacity))
            case .board: board.transition(.opacity)
            }
        }
        .onChange(of: leg) { l in chrome.curtain = (l != .lobby) }
        .onAppear { if roster.isEmpty { roster = seedRoster() } }
    }

    private var lobby: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Placard("pass the phone", size: 9, color: Ink.cobalt)
                        Slug(text: "Bout", size: 34)
                    }
                    Spacer()
                    Button {
                        Bumper.tap(.light)
                        chrome.bout.append(.archive)
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(vault.bouts.count)")
                                .font(.placard(20, .light)).foregroundColor(Ink.bone)
                            Placard("past", size: 8, color: Ink.flare)
                        }
                    }
                    .buttonStyle(.plain)
                }

                players
                packRow
                lapRow

                Button("Start the bout") {
                    round = 0
                    spoils = []
                    for i in roster.indices { roster[i].score = 0 }
                    deal()
                    hop(.handoff)
                }
                .buttonStyle(SlabButtonStyle(seed: 411, tall: 58))
                .disabled(roster.count < 2)
                .opacity(roster.count < 2 ? 0.35 : 1)

                Placard(roster.count < 2 ? "two players minimum" : "\(total) rounds · \(vault.nib?.seconds ?? 15)s each", size: 9)

                rules
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 130)
        }
    }

    private var rules: some View {
        Scrap(tilt: -1.1, seed: 417, taped: true) {
            VStack(alignment: .leading, spacing: 13) {
                Placard("how a lap goes", size: 9, color: Ink.cobalt)
                step("1", "The artist holds a finger on the card to read the word. Nobody else sees it.")
                step("2", "Fifteen seconds in the dark, same as solo.")
                step("3", "Phone goes to the next player. They name what they see.")
                step("4", "Right guess: guesser +2, artist +1 for being readable.")
            }
            .padding(18)
        }
        .padding(.top, 8)
    }

    private func step(_ n: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(n).font(.placard(13, .bold)).foregroundColor(Ink.flare).frame(width: 14, alignment: .leading)
            Text(body).font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(2.5)
        }
    }

    private var players: some View {
        VStack(alignment: .leading, spacing: 12) {
            Placard("at the table", size: 9)
            VStack(spacing: 8) {
                ForEach(roster) { p in
                    HStack(spacing: 12) {
                        Shaky { beat in
                            WobblyBlob(seed: beat &+ UInt64(abs(p.id.hashValue % 400)), amp: 1.6)
                                .fill(Ink.flare.opacity(0.85))
                                .frame(width: 10, height: 10)
                        }
                        Text(p.name.uppercased()).placardStyle(13, Ink.bone, weight: .semibold)
                        Spacer(minLength: 0)
                        Button {
                            Bumper.tap(.soft)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                roster.removeAll { $0.id == p.id }
                            }
                        } label: {
                            Shaky { beat in
                                CrossGlyph(seed: beat).stroke(Ink.faded, lineWidth: 1.4).frame(width: 12, height: 12)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 11)
                    .hairline(seed: UInt64(abs(p.id.hashValue % 300)))
                }
            }

            HStack(spacing: 10) {
                PlacardField(caption: "Add a player", text: $draft, limit: 12, seed: 413)
                Button("Add") { addPlayer() }
                    .buttonStyle(GhostButtonStyle(tint: draft.isEmpty ? Ink.faded : Ink.flare, seed: 415, tall: 46))
                    .frame(width: 84)
                    .padding(.top, 22)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || roster.count >= 8)
            }
        }
    }

    private var packRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Placard("words from", size: 9)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Pack.allCases) { p in
                        Button {
                            Bumper.tap(.light)
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { pack = p }
                        } label: {
                            Chip(text: p.title, on: pack == p, tint: p.stamp, seed: UInt64(abs(p.rawValue.hashValue % 350)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private var lapRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Placard("laps", size: 9)
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { n in
                    Button {
                        Bumper.tap(.light)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { laps = n }
                    } label: {
                        Chip(text: "\(n)", on: laps == n, seed: UInt64(n * 71))
                    }
                    .buttonStyle(.plain)
                }
                Placard("everyone draws \(laps)×", size: 9)
                    .padding(.leading, 6)
            }
        }
    }

    private var handoff: some View {
        VStack(spacing: 22) {
            Spacer()
            Placard("round \(round + 1) of \(total)", size: 10, color: Ink.flare)
            Text("PASS TO\n\(artist?.name.uppercased() ?? "")")
                .font(.slug(38)).tracking(-1.6).multilineTextAlignment(.center)
                .foregroundColor(Ink.bone)
                .overprint(Ink.flare, dx: 3, dy: -2.5, opacity: 0.4)

            Scrap(tilt: -1, fill: Ink.void, edge: peeking ? Ink.flare : Ink.bone.opacity(0.25), seed: 421, taped: true) {
                VStack(spacing: 10) {
                    if peeking {
                        Text(word.uppercased())
                            .font(.slug(word.count > 12 ? 22 : 30)).tracking(-1)
                            .multilineTextAlignment(.center)
                            .foregroundColor(Ink.bone)
                    } else {
                        Placard("hold to read your word", size: 11, color: Ink.faded)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 96)
                .padding(18)
            }
            .padding(.horizontal, 30)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !peeking { Bumper.tap(.soft) }
                        peeking = true
                    }
                    .onEnded { _ in peeking = false }
            )

            Text("Nobody else looks. Lift your finger and the word is gone.")
                .font(.system(size: 12.5)).foregroundColor(Ink.faded)
                .multilineTextAlignment(.center).frame(maxWidth: 250)

            Button("I'm ready") {
                peeking = false
                strokes = []
                hop(.draw)
            }
            .buttonStyle(SlabButtonStyle(seed: 423, tall: 56))
            .frame(width: 240)
            Spacer()
        }
        .padding(.horizontal, 22)
    }

    private var guessing: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                Placard(madeIt == nil ? "pass to \(guesser?.name ?? "")" : "round \(round + 1)", size: 10, color: Ink.cobalt)
                Slug(text: madeIt == nil ? "What is it?" : (madeIt == true ? "Read loud and clear" : "Nobody could read it"), size: 27)

                Scrap(tilt: 1.2, fill: Ink.void, edge: madeIt == nil ? Ink.bone.opacity(0.28) : (madeIt == true ? Ink.cobalt : Ink.flare), seed: 431, taped: true) {
                    ScrawlView(strokes: strokes, color: Ink.bone, weight: 2.8, offprint: false)
                        .padding(14)
                }
                .padding(.horizontal, 26)

                if madeIt == nil {
                    VStack(spacing: 9) {
                        ForEach(options, id: \.self) { o in
                            Button { score(o) } label: {
                                Scrap(tilt: 0, seed: UInt64(o.count * 17)) {
                                    Text(o.uppercased()).placardStyle(13, Ink.bone, weight: .semibold)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 17)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 22)
                } else {
                    VStack(spacing: 12) {
                        Text("It was \(word.uppercased()).")
                            .font(.slug(21)).tracking(-0.8).foregroundColor(Ink.bone)
                        Placard(madeIt == true
                                ? "\(guesser?.name ?? "") +2 · \(artist?.name ?? "") +1"
                                : "no points this round", size: 10, color: madeIt == true ? Ink.cobalt : Ink.faded)

                        Button(round + 1 >= total ? "Final tally" : "Next round") { nextLeg() }
                            .buttonStyle(SlabButtonStyle(seed: 433, tall: 54))
                            .frame(width: 240)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.top, 22)
            .padding(.bottom, 60)
        }
    }

    private var board: some View {
        let ranked = roster.sorted { $0.score > $1.score }
        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Placard("final tally", size: 10, color: Ink.flare)
                Text(ranked.first?.name.uppercased() ?? "")
                    .font(.slug(44)).tracking(-2).foregroundColor(Ink.bone)
                    .overprint(Ink.flare, dx: 3, dy: -2.5, opacity: 0.42)

                VStack(spacing: 0) {
                    ForEach(Array(ranked.enumerated()), id: \.element.id) { i, p in
                        HStack(spacing: 14) {
                            Text("\(i + 1)").font(.placard(15, .light)).foregroundColor(Ink.faded).frame(width: 22, alignment: .leading)
                            Text(p.name.uppercased()).placardStyle(13, i == 0 ? Ink.flare : Ink.bone, weight: .semibold)
                            Spacer(minLength: 0)
                            Text("\(p.score)").font(.placard(19, .light)).foregroundColor(Ink.bone)
                        }
                        .padding(.vertical, 14)
                        .hairline(seed: UInt64(abs(p.id.hashValue % 250)))
                    }
                }

                Text("\(spoils.count) drawings from this bout went onto the wall, signed by whoever made them.")
                    .font(.system(size: 13)).foregroundColor(Ink.faded).lineSpacing(3)

                Button("Back to the table") { hop(.lobby) }
                    .buttonStyle(SlabButtonStyle(seed: 441, tall: 54))
                Button("See the wall") {
                    hop(.lobby)
                    chrome.bay = .wall
                }
                .buttonStyle(GhostButtonStyle(seed: 443, tall: 46))
            }
            .padding(.horizontal, 22)
            .padding(.top, 26)
            .padding(.bottom, 120)
        }
    }

    private func seedRoster() -> [Player] {
        guard let me = vault.nib?.handle else { return [] }
        return [Player(name: me)]
    }

    private func addPlayer() {
        let name = draft.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        Bumper.tap(.light)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
            roster.append(Player(name: name))
            draft = ""
        }
    }

    private func deal() {
        let p = PromptBook.pick(from: [pack], avoiding: spoils.map(\.word))
        word = p.word
        var rng = Seeded(word: p.word + "\(round)")
        var opts = PromptBook.decoys(for: p.word, packs: [pack]) + [p.word]
        for i in stride(from: opts.count - 1, to: 0, by: -1) {
            opts.swapAt(i, rng.next(0..<(i + 1)))
        }
        options = opts
        madeIt = nil
    }

    private func score(_ guess: String) {
        let hit = guess == word
        Bumper.verdict(hit)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { madeIt = hit }
        if hit {
            if let g = guesser, let i = roster.firstIndex(where: { $0.id == g.id }) { roster[i].score += 2 }
            if let a = artist, let i = roster.firstIndex(where: { $0.id == a.id }) { roster[i].score += 1 }
        }
        if !strokes.isEmpty {
            spoils.append(Scrawl(
                word: word,
                pack: pack,
                bornAt: Date(),
                strokes: strokes,
                seconds: vault.nib?.seconds ?? 15,
                bet: nil,
                origin: .bout,
                artist: artist?.name,
                solved: hit
            ))
        }
    }

    private func nextLeg() {
        if round + 1 >= total {
            let bout = Bout(at: Date(), players: roster, scrawlIDs: spoils.map(\.id), pack: pack)
            vault.file(bout, drawings: spoils)
            hop(.board)
        } else {
            round += 1
            deal()
            hop(.handoff)
        }
    }

    private func hop(_ l: Leg) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { leg = l }
    }
}
