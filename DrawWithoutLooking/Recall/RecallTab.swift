import SwiftUI

private struct Trial: Identifiable {
    let id: UUID
    let scrawl: Scrawl

    let options: [String]

    var truth: String { scrawl.word }
}

struct RecallTab: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    @State private var queue: [Trial] = []
    @State private var cursor = 0
    @State private var drag: CGSize = .zero
    @State private var flash: Bool?
    @State private var hits = 0
    @State private var loaded = false

    private let throwLine: CGFloat = 74

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            VStack(spacing: 0) {
                head
                if queue.isEmpty {
                    ScrollView(showsIndicators: false) {
                        EmptyFrame(
                            headline: vault.curing > 0 ? "Still wet" : "Nothing to test",
                            note: emptyNote,
                            cta: "Draw blind"
                        ) { chrome.bay = .draw }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 140)
                    }
                } else if cursor >= queue.count {
                    tally
                } else {
                    table
                }
            }
        }
        .onAppear(perform: build)
    }

    private var emptyNote: String {
        let fresh = vault.curing
        guard fresh > 0 else {
            return "Recall needs a few drawings in the vault before it can quiz you. Go make some evidence."
        }
        return "\(fresh == 1 ? "One drawing is" : "\(fresh) drawings are") still too fresh. Naming a drawing you just made proves nothing — give the ink a day or two to leave your memory."
    }

    private var head: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Placard("do you know", size: 9, color: Ink.cobalt)
                Slug(text: "your own hand?", size: 25)
            }
            Spacer()
            Button {
                Bumper.tap(.light)
                chrome.recall.append(.report)
            } label: {
                VStack(spacing: 4) {
                    Text(vault.legibility.map { "\(Int($0 * 100))%" } ?? "—")
                        .font(.placard(20, .light)).foregroundColor(Ink.bone)
                    Placard("report", size: 8, color: Ink.flare)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var table: some View {
        let t = queue[cursor]
        return GeometryReader { geo in
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                ZStack {

                    VStack {
                        option(t.options[0], .up, live: dir == .up)
                        Spacer()
                        option(t.options[2], .down, live: dir == .down)
                    }
                    HStack {
                        option(t.options[3], .left, live: dir == .left)
                        Spacer(minLength: 8)
                        option(t.options[1], .right, live: dir == .right)
                    }

                    card(t)
                        .frame(width: min(162, geo.size.width * 0.42))
                        .offset(drag)
                        .rotationEffect(.degrees(Double(drag.width / 22)))
                        .gesture(
                            DragGesture()
                                .onChanged { v in drag = v.translation }
                                .onEnded { v in settle(v.translation, trial: t) }
                        )
                }
                .frame(height: min(430, geo.size.height - 60))
                Spacer(minLength: 0)
                Placard("swipe toward the answer", size: 8, color: Ink.faded.opacity(0.7))
                    .padding(.bottom, 10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 96)
    }

    private enum Way { case up, down, left, right, none }

    private var dir: Way {
        guard hypot(drag.width, drag.height) > 26 else { return .none }
        if abs(drag.width) > abs(drag.height) { return drag.width > 0 ? .right : .left }
        return drag.height > 0 ? .down : .up
    }

    private func card(_ t: Trial) -> some View {
        Scrap(tilt: lean(t.id, range: 1.8), fill: Ink.void, edge: edgeTint, seed: UInt64(abs(t.id.hashValue % 800)), taped: true, lineWidth: 1.8) {
            VStack(spacing: 10) {
                ScrawlView(strokes: t.scrawl.strokes, color: Ink.bone, weight: 2.4, offprint: false)
                Placard(t.scrawl.origin == .bout ? "drawn by \(t.scrawl.artist ?? "someone")" : "drawn \(ago(t.scrawl.bornAt))", size: 8)
            }
            .padding(14)
        }
        .overlay {
            if let flash {
                Shaky { beat in
                    Group {
                        if flash {
                            TickGlyph(seed: beat).stroke(Ink.cobalt, style: StrokeStyle(lineWidth: 5, lineJoin: .round))
                        } else {
                            CrossGlyph(seed: beat).stroke(Ink.flare, lineWidth: 5)
                        }
                    }
                    .frame(width: 64, height: 60)
                }
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
    }

    private var edgeTint: Color {
        switch flash {
        case .some(true): return Ink.cobalt
        case .some(false): return Ink.flare
        default: return dir == .none ? Ink.bone.opacity(0.3) : Ink.flare.opacity(0.8)
        }
    }

    private func option(_ word: String, _ way: Way, live: Bool) -> some View {
        Placard(word, size: live ? 11 : 10, color: live ? Ink.base : Ink.faded, weight: live ? .bold : .medium)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(maxWidth: 96)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Shaky { beat in
                    WobblyRect(radius: 8, seed: beat &+ UInt64(word.count * 13), amp: 1.3)
                        .fill(live ? Ink.flare : Color.clear)
                }
            )
            .overlay(
                Shaky { beat in
                    WobblyRect(radius: 8, seed: beat &+ UInt64(word.count * 13), amp: 1.3)
                        .stroke(live ? Ink.flare : Ink.faded.opacity(0.4), lineWidth: 1.2)
                }
            )
            .scaleEffect(live ? 1.08 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: live)
    }

    private var tally: some View {
        VStack(spacing: 18) {
            Spacer()
            Text("\(hits)/\(queue.count)")
                .font(.slug(64)).tracking(-3).foregroundColor(Ink.bone)
                .overprint(Ink.cobalt, dx: 3, dy: -2.5, opacity: 0.4)
            Text(hits * 2 >= queue.count
                 ? "You still speak your own language. Barely."
                 : "Your hand writes in a script you cannot read.")
                .font(.system(size: 14)).foregroundColor(Ink.faded)
                .multilineTextAlignment(.center).frame(maxWidth: 270)

            Button("See the report") { chrome.recall.append(.report) }
                .buttonStyle(SlabButtonStyle(tint: Ink.cobalt, label: Ink.bone, seed: 331, tall: 52))
                .frame(width: 230)
            Button("Deal again") {
                hits = 0
                loaded = false
                build()
            }
            .buttonStyle(GhostButtonStyle(seed: 333, tall: 44))
            .frame(width: 230)
            Spacer()
        }
        .padding(.bottom, 90)
    }

    private func build() {
        guard !loaded else { return }
        let deck = vault.recallDeck()
        guard deck.count >= 3 else {
            queue = []
            loaded = true
            return
        }
        queue = deck.prefix(8).map { s in
            var rng = Seeded(word: s.word + s.id.uuidString)
            var opts = PromptBook.decoys(for: s.word, packs: vault.nib?.packs ?? Pack.allCases) + [s.word]

            for i in stride(from: opts.count - 1, to: 0, by: -1) {
                opts.swapAt(i, rng.next(0..<(i + 1)))
            }
            return Trial(id: s.id, scrawl: s, options: opts)
        }
        cursor = 0
        loaded = true
    }

    private func settle(_ t: CGSize, trial: Trial) {
        let way = dir
        guard hypot(t.width, t.height) > throwLine, way != .none else {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { drag = .zero }
            return
        }
        let idx: Int
        switch way {
        case .up: idx = 0
        case .right: idx = 1
        case .down: idx = 2
        case .left: idx = 3
        case .none: return
        }
        let guessed = trial.options[idx]
        let hit = guessed == trial.truth
        if hit { hits += 1 }
        vault.noteRecall(trial.scrawl.id, guessed: guessed, hit: hit)
        Bumper.verdict(hit)

        withAnimation(.easeOut(duration: 0.2)) { flash = hit }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                flash = nil
                drag = .zero
                cursor += 1
            }
        }
    }

    private func ago(_ d: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: d, to: Date()).day ?? 0
        switch days {
        case ..<1: return "today"
        case 1: return "yesterday"
        default: return "\(days) days ago"
        }
    }
}
