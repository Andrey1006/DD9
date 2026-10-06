
import SwiftUI

struct Intake: View {
    @EnvironmentObject private var vault: Vault

    private enum Step { case name, packs, brief, blind, reading, tempo }

    @State private var step: Step = .name
    @State private var handle = ""
    @State private var packs: Set<Pack> = [.animals, .kitchen]
    @State private var tempo: Tempo = .standard
    @State private var haptics = true
    @State private var sonar = true
    @State private var strokes: [Stroke] = []
    @State private var developed = false

    private let calibrationSeconds = 8

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            if step == .blind {
                Blackout(seconds: calibrationSeconds, word: "a circle", trust: false, sonarOn: sonar) { s in
                    strokes = s
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { step = .reading }
                }
                .transition(.opacity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        marks
                        page
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 26)
                    .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
    }

    private var marks: some View {
        HStack(spacing: 7) {
            ForEach(0..<4, id: \.self) { i in
                Shaky { beat in
                    WobblyRect(radius: 3, seed: beat &+ UInt64(i * 31), amp: 1.2, step: 6)
                        .fill(i <= chapter ? Ink.flare : Ink.smoke)
                }
                .frame(width: 26, height: 5)
            }
            Spacer()
            Placard("\(chapter + 1)/4", size: 10)
        }
    }

    private var chapter: Int {
        switch step {
        case .name: return 0
        case .packs: return 1
        case .brief, .blind, .reading: return 2
        case .tempo: return 3
        }
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case .name: nameStep
        case .packs: packStep
        case .brief: briefStep
        case .reading: readingStep
        case .tempo: tempoStep
        case .blind: EmptyView()
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("INK\nHAND\nDIARY")
                .font(.slug(52))
                .tracking(-2.4)
                .lineSpacing(-6)
                .foregroundColor(Ink.bone)
                .overprint(Ink.flare, dx: 3, dy: -2.5, opacity: 0.42)

            Text("A word. Fifteen seconds. A black screen. Whatever your hand does next goes on the wall forever.")
                .font(.system(size: 15))
                .foregroundColor(Ink.faded)
                .lineSpacing(4)

            PlacardField(caption: "Sign the wall as", text: $handle, seed: 141)
                .padding(.top, 6)

            Button("Next") { advance(.packs) }
                .buttonStyle(SlabButtonStyle(seed: 143))
                .disabled(trimmed.isEmpty)
                .opacity(trimmed.isEmpty ? 0.35 : 1)

            Spacer(minLength: 40)

            VStack(alignment: .leading, spacing: 6) {
                Shaky { beat in
                    WobblyLine(seed: beat &+ 145).stroke(Ink.bone.opacity(0.14), lineWidth: 1.2).frame(height: 4)
                }
                Placard("no account · no internet · nothing leaves the phone", size: 8, color: Ink.faded.opacity(0.7))
            }
        }
    }

    private var trimmed: String {
        handle.trimmingCharacters(in: .whitespaces)
    }

    private var packStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Slug(text: "What should\nwe throw at you", size: 30)
            Text("Pick at least two. This is the pool every prompt comes from — solo and in company.")
                .font(.system(size: 14)).foregroundColor(Ink.faded).lineSpacing(3)

            VStack(spacing: 10) {
                ForEach(Pack.allCases) { p in
                    packRow(p)
                }
            }

            Button("Next") { advance(.brief) }
                .buttonStyle(SlabButtonStyle(seed: 151))
                .disabled(packs.count < 2)
                .opacity(packs.count < 2 ? 0.35 : 1)
        }
    }

    private func packRow(_ p: Pack) -> some View {
        let on = packs.contains(p)
        return Button {
            Bumper.tap(.light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if on { packs.remove(p) } else { packs.insert(p) }
            }
        } label: {
            Scrap(tilt: on ? -0.7 : 0, fill: on ? Ink.smoke : Ink.soot, edge: on ? p.stamp : Ink.bone.opacity(0.16), seed: UInt64(abs(p.rawValue.hashValue % 500))) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(p.title.uppercased()).placardStyle(13, on ? Ink.bone : Ink.faded, weight: .bold)
                        Text(p.blurb).font(.system(size: 12)).foregroundColor(Ink.faded.opacity(0.85))
                    }
                    Spacer(minLength: 6)
                    Shaky { beat in
                        Group {
                            if on {
                                TickGlyph(seed: beat).stroke(p.stamp, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
                            } else {
                                WobblyRect(radius: 4, seed: beat, amp: 1).stroke(Ink.faded.opacity(0.4), lineWidth: 1.2)
                            }
                        }
                        .frame(width: 18, height: 16)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
            }
        }
        .buttonStyle(.plain)
    }

    private var briefStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Slug(text: "First, a circle", size: 32)
            Text("Eight seconds, screen dark, no line to follow. Draw one circle. We are not judging it — we are measuring where your hand actually goes when nobody shows it.")
                .font(.system(size: 14.5)).foregroundColor(Ink.faded).lineSpacing(4)

            Scrap(tilt: -1.1, seed: 161, taped: true) {
                VStack(alignment: .leading, spacing: 12) {
                    hint("Edges tick", "A sharp buzz means you hit the border.")
                    hint("Pitch is height", "The tone rises as your finger goes up.")
                    hint("Lifting counts", "Every lift starts a new stroke.")
                }
                .padding(18)
            }

            SwitchRow(title: "Sound on", note: "The pitch guide. Works with headphones too.", on: $sonar, seed: 163)
                .padding(.top, 2)

            Button("Go dark") {
                Bumper.warm()
                advance(.blind)
            }
            .buttonStyle(SlabButtonStyle(seed: 167))
        }
    }

    private func hint(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Placard(title, size: 10, color: Ink.flare, weight: .semibold)
            Text(body).font(.system(size: 12.5)).foregroundColor(Ink.faded)
        }
    }

    private var readingStep: some View {
        let drift = DriftReader.measure(strokes)
        return VStack(alignment: .leading, spacing: 20) {
            Slug(text: developed ? "So that's your hand" : "Develop it", size: 30)

            Scrap(tilt: 1.2, fill: Ink.void, edge: Ink.bone.opacity(0.3), seed: 171, taped: true) {
                Develop(strokes: strokes) {
                    withAnimation(.easeOut(duration: 0.4)) { developed = true }
                }
                .padding(10)
            }

            if let drift {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your hand lands \(Int(drift.offPoints)) pt \(drift.bearing) of centre and draws \(drift.sizing).")
                        .font(.system(size: 14)).foregroundColor(Ink.bone).lineSpacing(3)
                    Text("Every round refines this. Later you can hit STRAIGHTEN on any drawing to undo your own bias.")
                        .font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(3)
                }
                .opacity(developed ? 1 : 0.15)
                .animation(.easeOut(duration: 0.35), value: developed)
            } else {
                Text("Nothing landed on the canvas. That happens — the next one will.")
                    .font(.system(size: 13)).foregroundColor(Ink.faded)
            }

            Button("Next") { advance(.tempo) }
                .buttonStyle(SlabButtonStyle(seed: 173))
                .disabled(!developed && !strokes.isEmpty)
                .opacity(!developed && !strokes.isEmpty ? 0.35 : 1)
        }
    }

    private var tempoStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Slug(text: "How long\ndo you get", size: 30)

            VStack(spacing: 10) {
                ForEach(Tempo.allCases) { t in
                    Button {
                        Bumper.tap(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) { tempo = t }
                    } label: {
                        Scrap(tilt: tempo == t ? 0.8 : 0, fill: tempo == t ? Ink.smoke : Ink.soot, edge: tempo == t ? Ink.flare : Ink.bone.opacity(0.16), seed: UInt64(t.rawValue * 7)) {
                            HStack(spacing: 14) {
                                Text("\(t.rawValue)")
                                    .font(.placard(28, .light))
                                    .foregroundColor(tempo == t ? Ink.flare : Ink.faded)
                                    .frame(width: 46, alignment: .leading)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(t.title.uppercased()).placardStyle(12, Ink.bone, weight: .bold)
                                    Text(t.blurb).font(.system(size: 12)).foregroundColor(Ink.faded)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            SwitchRow(title: "Haptics", note: "Edge ticks and stroke lifts.", on: $haptics, seed: 181)

            Button("Open the studio", action: settle)
                .buttonStyle(SlabButtonStyle(seed: 183))
                .padding(.top, 4)
        }
    }

    private func advance(_ to: Step) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step = to }
    }

    private func settle() {
        var nib = Nib.fresh(handle: trimmed.isEmpty ? "Anon" : trimmed)
        nib.packs = Pack.allCases.filter { packs.contains($0) }
        nib.seconds = tempo.rawValue
        nib.haptics = haptics
        nib.sonar = sonar
        nib.calibration = DriftReader.measure(strokes)

        if !strokes.isEmpty {
            vault.keep(Scrawl(
                word: "a circle",
                pack: .absurd,
                bornAt: Date(),
                strokes: strokes,
                seconds: calibrationSeconds,
                bet: nil,
                origin: .calibration,
                artist: nib.handle
            ))
        }
        Bumper.verdict(true)
        vault.nib = nib
    }
}
