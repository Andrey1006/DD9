import SwiftUI

struct Legibility: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    private var tested: [Scrawl] { vault.scrawls.filter { !$0.recalls.isEmpty } }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headline
                    if tested.isEmpty {
                        EmptyFrame(
                            headline: "No verdicts yet",
                            note: "Swipe through a few Recall cards and this page fills with the uncomfortable truth."
                        )
                    } else {
                        packBars
                        rejects
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 60)
            }
        }
        .pushedScreen("Recall") { chrome.recall.removeLast() }
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Placard("legibility report", size: 9, color: Ink.cobalt)
            Text(vault.legibility.map { "\(Int($0 * 100))%" } ?? "—")
                .font(.slug(66)).tracking(-3).foregroundColor(Ink.bone)
                .overprint(Ink.cobalt, dx: 3, dy: -2.5, opacity: 0.4)
            Text("of your own drawings you recognised on sight, across \(vault.scrawls.flatMap(\.recalls).count) tests.")
                .font(.system(size: 14)).foregroundColor(Ink.faded).lineSpacing(3)
        }
        .padding(.top, 6)
    }

    private var packBars: some View {
        VStack(alignment: .leading, spacing: 14) {
            Placard("by pack", size: 9)
            ForEach(Pack.allCases) { p in
                let score = vault.legibility(of: p)
                HStack(spacing: 12) {
                    Placard(p.title, size: 10, color: score == nil ? Ink.faded.opacity(0.5) : Ink.bone)
                        .frame(width: 78, alignment: .leading)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Shaky { beat in
                                WobblyRect(radius: 5, seed: beat &+ UInt64(abs(p.rawValue.hashValue % 300)), amp: 1.2, step: 9)
                                    .stroke(Ink.bone.opacity(0.14), lineWidth: 1.1)
                            }
                            if let score {
                                Shaky { beat in
                                    WobblyRect(radius: 5, seed: beat &+ UInt64(abs(p.rawValue.hashValue % 300)) &+ 5, amp: 1.2, step: 9)
                                        .fill(p.stamp.opacity(0.75))
                                }
                                .frame(width: max(10, geo.size.width * score))
                            }
                        }
                    }
                    .frame(height: 16)
                    Placard(score.map { "\(Int($0 * 100))" } ?? "–", size: 10, color: score == nil ? Ink.faded.opacity(0.4) : Ink.bone)
                        .frame(width: 26, alignment: .trailing)
                }
            }
        }
    }

    private var rejects: some View {
        let bad = vault.scrawls.filter(\.unreadable)
        return VStack(alignment: .leading, spacing: 12) {
            Placard(bad.isEmpty ? "nothing unreadable — yet" : "you failed to read these", size: 9, color: bad.isEmpty ? Ink.faded : Ink.flare)
            if bad.isEmpty {
                Text("Every drawing you were shown, you named. Either you are good at this or Recall has been gentle so far.")
                    .font(.system(size: 13)).foregroundColor(Ink.faded).lineSpacing(3)
            } else {
                ForEach(bad) { s in
                    Button {
                        Bumper.tap(.light)
                        chrome.openExhibit(s.id)
                    } label: {
                        HStack(spacing: 14) {
                            ScrawlView(strokes: s.strokes, color: Ink.bone.opacity(0.85), weight: 1.6, offprint: false)
                                .frame(width: 54, height: 54)
                                .background(Ink.void.opacity(0.6))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(s.word.uppercased()).placardStyle(12, Ink.bone, weight: .semibold)
                                Placard("guessed: " + s.recalls.map(\.guessed).joined(separator: ", "), size: 8)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .hairline(seed: UInt64(abs(s.id.hashValue % 200)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
