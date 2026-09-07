import SwiftUI

struct WordPicker: View {
    let packs: [Pack]
    let onPick: (Prompt) -> Void

    @State private var probe = ""

    private var hits: [Prompt] {
        let pool = PromptBook.pool(packs)
        let q = probe.trimmingCharacters(in: .whitespaces).lowercased()
        return q.isEmpty ? pool : pool.filter { $0.word.contains(q) }
    }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Slug(text: "Pick a word", size: 24)
                    Spacer()
                    Placard("\(hits.count)", size: 11, color: Ink.flare)
                }
                .padding(.top, 22)

                PlacardField(caption: "Filter", text: $probe, limit: 20, seed: 261)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 8) {
                        ForEach(hits, id: \.word) { p in
                            Button {
                                Bumper.tap(.light)
                                onPick(p)
                            } label: {
                                HStack(spacing: 12) {
                                    Shaky { beat in
                                        WobblyBlob(seed: beat &+ UInt64(p.word.count), amp: 1.4)
                                            .fill(p.pack.stamp.opacity(0.9))
                                            .frame(width: 8, height: 8)
                                    }
                                    Text(p.word.uppercased()).placardStyle(13, Ink.bone, weight: .semibold)
                                    Spacer(minLength: 0)
                                    Placard(String(repeating: "•", count: p.heat), size: 12, color: Ink.faded.opacity(0.7))
                                }
                                .padding(.vertical, 13)
                                .padding(.horizontal, 14)
                                .contentShape(Rectangle())
                                .hairline(seed: UInt64(p.word.count * 7))
                            }
                            .buttonStyle(.plain)
                        }

                        if hits.isEmpty {
                            EmptyFrame(
                                headline: "No such word",
                                note: "Nothing in your packs matches that. Clear the filter or add packs in You."
                            )
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .padding(.horizontal, 22)
        }
    }
}
