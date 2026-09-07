import Combine
import SwiftUI

struct DrawTab: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    private enum Beat { case stage, brief, blind, bet, plate }

    @State private var beat: Beat = .stage
    @State private var word = ""
    @State private var pack: Pack = .animals
    @State private var strokes: [Stroke] = []
    @State private var call: Bet?
    @State private var kept: UUID?
    @State private var developed = false
    @State private var straight = false
    @State private var briefLeft = 3
    @State private var picking = false

    private let briefClock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var nib: Nib { vault.nib ?? .fresh(handle: "Anon") }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            switch beat {
            case .stage: stage.transition(.opacity)
            case .brief: brief.transition(.scale(scale: 0.94).combined(with: .opacity))
            case .blind:
                Blackout(seconds: nib.seconds, word: word, trust: nib.trustMode, sonarOn: nib.sonar) { s in
                    strokes = s
                    step(.bet)
                }
                .transition(.opacity)
            case .bet: betting.transition(.move(edge: .bottom).combined(with: .opacity))
            case .plate: plate.transition(.opacity)
            }
        }
        .sheet(isPresented: $picking) {
            WordPicker(packs: nib.packs) { p in
                picking = false
                launch(p)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
        .onChange(of: beat) { b in
            chrome.curtain = (b != .stage)
        }
        .onReceive(briefClock) { _ in
            guard beat == .brief else { return }
            briefLeft -= 1
            if briefLeft <= 0 { step(.blind) }
        }
    }

    private var stage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                dailyCard
                startBlock
                driftCard
                lately
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 152)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Placard("studio of", size: 10)
                Text(nib.handle.uppercased())
                    .font(.slug(34)).tracking(-1.4).foregroundColor(Ink.bone)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(vault.streak)")
                    .font(.placard(30, .light))
                    .foregroundColor(vault.streak > 0 ? Ink.flare : Ink.faded)
                Placard(vault.streak == 1 ? "day streak" : "days streak", size: 8)
            }
        }
        .padding(.bottom, 2)
    }

    private var dailyCard: some View {
        let daily = PromptBook.ofTheDay(nib.packs)
        return Scrap(tilt: -1.3, fill: Ink.soot, edge: daily.pack.stamp.opacity(0.6), seed: 211, taped: true) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Placard("word of the day", size: 9, color: daily.pack.stamp)
                    Spacer()
                    Placard(daily.pack.title, size: 9)
                }
                Text(daily.word.uppercased())
                    .font(.slug(32)).tracking(-1.2).foregroundColor(Ink.bone)
                    .overprint(daily.pack.stamp, dx: 2.4, dy: -2, opacity: 0.35)
                Button("Take it") { launch(daily) }
                    .buttonStyle(GhostButtonStyle(tint: daily.pack.stamp, seed: 213, tall: 42))
            }
            .padding(18)
        }
        .padding(.top, 4)
    }

    private var startBlock: some View {
        VStack(spacing: 12) {
            Button(vault.roundsToday == 0 ? "Draw blind" : "Another one") {
                launch(PromptBook.pick(from: nib.packs, avoiding: vault.recentWords))
            }
            .buttonStyle(SlabButtonStyle(seed: 217, tall: 62))

            Button("Choose the word myself") { picking = true }
                .buttonStyle(GhostButtonStyle(seed: 219, tall: 44))

            Placard("\(nib.seconds) seconds · \(nib.packs.count) packs · \(vault.roundsToday) today", size: 9)
                .padding(.top, 2)
        }
    }

    private var driftCard: some View {
        let d = vault.drift
        return Scrap(tilt: 0.9, seed: 221) {
            HStack(spacing: 18) {
                DriftDial(drift: d, side: 92)
                VStack(alignment: .leading, spacing: 7) {
                    Placard("your hand", size: 9)
                    Text("\(Int(d.offPoints)) pt \(d.bearing)")
                        .font(.slug(21)).tracking(-0.6).foregroundColor(Ink.bone)
                    Text("Draws \(d.sizing). Measured over your last rounds, not once at signup.")
                        .font(.system(size: 11.5)).foregroundColor(Ink.faded).lineSpacing(2)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private var lately: some View {
        let recent = Array(vault.scrawls.prefix(5))
        return VStack(alignment: .leading, spacing: 11) {
            HStack {
                Placard("lately", size: 9)
                Spacer()
                if !recent.isEmpty {
                    Button {
                        Bumper.tap(.light)
                        chrome.bay = .wall
                    } label: {
                        Placard("the wall", size: 9, color: Ink.flare, weight: .semibold)
                    }
                    .buttonStyle(.plain)
                }
            }

            if recent.isEmpty {
                Text("Nothing hangs on the wall yet. The next round starts the collection.")
                    .font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(3)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 11) {
                        ForEach(recent) { s in
                            Button {
                                Bumper.tap(.light)
                                chrome.openExhibit(s.id)
                            } label: {
                                VStack(spacing: 6) {
                                    ScrawlView(strokes: s.strokes, color: Ink.bone.opacity(0.88), weight: 1.5, offprint: false)
                                        .frame(width: 68, height: 68)
                                        .background(Ink.void.opacity(0.6))
                                        .overlay(
                                            Shaky { beat in
                                                WobblyRect(radius: 5, seed: beat &+ UInt64(abs(s.id.hashValue % 500)), amp: 1.2)
                                                    .stroke(Ink.bone.opacity(0.18), lineWidth: 1)
                                            }
                                        )
                                    Placard(s.word, size: 7, color: Ink.faded)
                                        .frame(width: 72)
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.top, 4)
    }

    private var brief: some View {
        VStack(spacing: 26) {
            Spacer()
            Placard(pack.title, size: 10, color: pack.stamp)
            Text(word.uppercased())
                .font(.slug(word.count > 12 ? 34 : 46))
                .tracking(-1.8)
                .multilineTextAlignment(.center)
                .foregroundColor(Ink.bone)
                .overprint(pack.stamp, dx: 3, dy: -2.5, opacity: 0.45)
                .padding(.horizontal, 30)
            Placard("memorise it — the screen goes dark", size: 10)
            Spacer()
            Text("\(briefLeft)")
                .font(.placard(48, .ultraLight))
                .foregroundColor(Ink.flare)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { step(.blind) }
    }

    private var betting: some View {
        VStack(alignment: .leading, spacing: 18) {
            Spacer()
            Placard("before you look", size: 10, color: Ink.flare)
            Slug(text: "How bad is it?", size: 34)
            Text("Call it now. The gap between your nerve and the actual drawing is half the fun.")
                .font(.system(size: 14)).foregroundColor(Ink.faded).lineSpacing(3)

            VStack(spacing: 11) {
                ForEach(Bet.allCases.reversed(), id: \.rawValue) { b in
                    Button {
                        call = b
                        commit()
                        step(.plate)
                    } label: {
                        Scrap(tilt: Double(b.rawValue) - 1, seed: UInt64(231 + b.rawValue)) {
                            HStack(spacing: 14) {
                                Text(b.mark)
                                    .font(.placard(18, .bold))
                                    .foregroundColor(Ink.flare)
                                    .frame(width: 30)
                                Text(b.call.uppercased()).placardStyle(13, Ink.bone, weight: .semibold)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var plate: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Placard(developed ? word : "developing", size: 10, color: pack.stamp)
                    Spacer()
                    if let call { Placard("you called: \(call.call)", size: 9) }
                }

                Scrap(tilt: 1.4, fill: Ink.void, edge: Ink.bone.opacity(0.3), seed: 241, taped: true) {
                    Group {
                        if straight {
                            ScrawlView(strokes: DriftReader.straighten(strokes, by: vault.drift), weight: 3)
                                .transition(.opacity)
                        } else {
                            Develop(strokes: strokes) {
                                withAnimation(.easeOut(duration: 0.4)) { developed = true }
                            }
                        }
                    }
                    .padding(12)
                }

                if developed {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(verdict)
                            .font(.system(size: 14.5)).foregroundColor(Ink.bone).lineSpacing(3)

                        Button(straight ? "Show it raw" : "Straighten by my drift") {
                            Bumper.tap(.light)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { straight.toggle() }
                        }
                        .buttonStyle(GhostButtonStyle(tint: Ink.cobalt, seed: 243, tall: 44))

                        HStack(spacing: 10) {
                            Button("Toss it") { discard() }
                                .buttonStyle(GhostButtonStyle(tint: Ink.faded, seed: 245, tall: 50))
                            Button("Again") { launch(PromptBook.pick(from: nib.packs, avoiding: vault.recentWords)) }
                                .buttonStyle(SlabButtonStyle(seed: 247, tall: 50))
                        }

                        Button("Back to the studio") { step(.stage) }
                            .buttonStyle(GhostButtonStyle(tint: Ink.faded, seed: 249, tall: 40))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 60)
        }
    }

    private var verdict: String {
        if strokes.isEmpty { return "Nothing landed. The canvas stayed clean — that is its own kind of result." }
        let d = DriftReader.measure(strokes) ?? .centred
        switch call {
        case .masterpiece: return "You called it a masterpiece. It landed \(Int(d.offPoints)) pt \(d.bearing). Post it and let Recall decide."
        case .disaster: return "You called it a wreck. Recall will tell you in a few days whether you were right."
        default: return "Filed. It went \(Int(d.offPoints)) pt \(d.bearing) of centre, \(d.sizing)."
        }
    }

    private func launch(_ p: Prompt) {
        word = p.word
        pack = p.pack
        strokes = []
        call = nil
        kept = nil
        developed = false
        straight = false
        briefLeft = 3
        Bumper.warm()
        step(.brief)
    }

    private func commit() {
        guard !strokes.isEmpty else { return }
        let s = Scrawl(
            word: word,
            pack: pack,
            bornAt: Date(),
            strokes: strokes,
            seconds: nib.seconds,
            bet: call,
            origin: .solo,
            artist: nib.handle
        )
        kept = s.id
        vault.keep(s)
    }

    private func discard() {
        if let kept { vault.toss(kept) }
        Bumper.tap(.soft)
        step(.stage)
    }

    private func step(_ b: Beat) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { beat = b }
    }
}
