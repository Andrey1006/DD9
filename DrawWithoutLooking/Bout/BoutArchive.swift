import SwiftUI

struct BoutArchive: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Placard("past bouts", size: 9, color: Ink.cobalt)
                        .padding(.top, 6)

                    if vault.bouts.isEmpty {
                        EmptyFrame(
                            headline: "No bouts played",
                            note: "Get two people around one phone and the scoreboards start piling up here."
                        )
                    } else {
                        ForEach(vault.bouts) { b in
                            Scrap(tilt: lean(b.id, range: 1.2), seed: UInt64(abs(b.id.hashValue % 600))) {
                                VStack(alignment: .leading, spacing: 11) {
                                    HStack {
                                        Text(b.champion?.name.uppercased() ?? "—")
                                            .font(.slug(22)).tracking(-0.8).foregroundColor(Ink.flare)
                                        Spacer()
                                        Placard(b.pack.title, size: 9, color: b.pack.stamp)
                                    }
                                    Placard(b.tally, size: 10, color: Ink.bone)
                                    Placard("\(b.scrawlIDs.count) drawings · \(b.at.formatted(date: .abbreviated, time: .shortened))", size: 8)

                                    let alive = b.scrawlIDs.compactMap { vault.scrawl($0) }
                                    if !alive.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(alive) { s in
                                                    Button {
                                                        Bumper.tap(.light)
                                                        chrome.openExhibit(s.id)
                                                    } label: {
                                                        ScrawlView(strokes: s.strokes, color: Ink.bone.opacity(0.85), weight: 1.5, offprint: false)
                                                            .frame(width: 62, height: 62)
                                                            .background(Ink.void.opacity(0.6))
                                                            .overlay(
                                                                Shaky { beat in
                                                                    WobblyRect(radius: 5, seed: beat &+ UInt64(abs(s.id.hashValue % 500)), amp: 1.2)
                                                                        .stroke(Ink.bone.opacity(0.2), lineWidth: 1)
                                                                }
                                                            )
                                                    }
                                                    .buttonStyle(.plain)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 60)
            }
        }
        .pushedScreen("Bout") { chrome.bout.removeLast() }
    }
}
