
import SwiftUI

struct YouTab: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    private var nib: Nib { vault.nib ?? .fresh(handle: "Anon") }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    figures
                    handCard
                    packEditor
                    workshopLink
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)
                .padding(.bottom, 130)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Placard("signed", size: 9)
                Text(nib.handle.uppercased())
                    .font(.slug(36)).tracking(-1.6).foregroundColor(Ink.bone)
                    .overprint(Ink.flare, dx: 2.6, dy: -2, opacity: 0.38)
                Placard("drawing blind since \(DayKey.string(nib.since))", size: 8)
            }
            Spacer()
        }
    }

    private var figures: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            tile(String(vault.scrawls.count), "on the wall", Ink.bone)
            tile("\(vault.streak)", vault.streak == 1 ? "day in a row" : "days in a row", vault.streak > 0 ? Ink.flare : Ink.faded)
            tile(vault.legibility.map { "\(Int($0 * 100))%" } ?? "—", "legible to you", Ink.cobalt)
            tile(nerve, "nerve", Ink.bone)
            tile(favourite?.title ?? "—", "most drawn", favourite?.stamp ?? Ink.faded)
            tile("\(vault.scrawls.flatMap(\.recalls).count)", "recall tests", Ink.bone)
        }
    }

    private func tile(_ value: String, _ caption: String, _ tint: Color) -> some View {
        Scrap(tilt: 0, seed: UInt64(abs(caption.hashValue % 500))) {
            VStack(alignment: .leading, spacing: 7) {
                Text(value.uppercased())
                    .font(.slug(value.count > 4 ? 19 : 30))
                    .tracking(-1)
                    .foregroundColor(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Placard(caption, size: 8)
                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 92, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var nerve: String {
        let called = vault.scrawls.filter { $0.bet != nil && !$0.recalls.isEmpty }
        guard !called.isEmpty else { return "untested" }
        let bold = called.filter { ($0.bet?.rawValue ?? 0) >= 1 && $0.unreadable }.count
        return bold == 0 ? "honest" : "\(bold) bluffs"
    }

    private var favourite: Pack? {
        var count: [Pack: Int] = [:]
        for s in vault.scrawls { count[s.pack, default: 0] += 1 }
        return count.max { $0.value < $1.value }?.key
    }

    private var handCard: some View {
        let d = vault.drift
        return Scrap(tilt: -1, seed: 511, taped: true) {
            HStack(spacing: 18) {
                DriftDial(drift: d, side: 104)
                VStack(alignment: .leading, spacing: 8) {
                    Placard("the hand", size: 9, color: Ink.flare)
                    Text("\(Int(d.offPoints)) pt \(d.bearing)")
                        .font(.slug(22)).tracking(-0.8).foregroundColor(Ink.bone)
                    Text("Draws \(d.sizing).")
                        .font(.system(size: 12.5)).foregroundColor(Ink.faded)
                    if nib.calibration != nil {
                        Placard("seeded at signup", size: 8)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private var packEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Placard("your packs", size: 9)
            Text("Prompts come from here. Solo rounds and word of the day both read this list.")
                .font(.system(size: 12.5)).foregroundColor(Ink.faded)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], spacing: 8) {
                ForEach(Pack.allCases) { p in
                    Button { toggle(p) } label: {
                        Chip(text: p.title, on: nib.packs.contains(p), tint: p.stamp, seed: UInt64(abs(p.rawValue.hashValue % 380)))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func toggle(_ p: Pack) {
        guard var n = vault.nib else { return }
        if n.packs.contains(p) {

            guard n.packs.count > 1 else {
                Bumper.verdict(false)
                return
            }
            n.packs.removeAll { $0 == p }
        } else {
            n.packs.append(p)
        }
        Bumper.tap(.light)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { vault.nib = n }
    }

    private var workshopLink: some View {
        Button {
            Bumper.tap(.light)
            chrome.you.append(.settings)
        } label: {
            Scrap(tilt: 0.7, fill: Ink.smoke, edge: Ink.bone.opacity(0.22), seed: 513) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Placard("workshop", size: 11, color: Ink.bone, weight: .bold)
                        Text("Tempo, sound, haptics, privacy, and the big red lever.")
                            .font(.system(size: 12)).foregroundColor(Ink.faded)
                    }
                    Spacer(minLength: 0)
                    Shaky { beat in
                        ArrowGlyph(seed: beat &+ 515)
                            .stroke(Ink.flare, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                            .frame(width: 20, height: 13)
                    }
                }
                .padding(17)
            }
        }
        .buttonStyle(.plain)
    }
}
