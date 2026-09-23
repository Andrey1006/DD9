import SwiftUI

private enum Hang: String, CaseIterable, Identifiable {
    case all, pinned, unreadable
    var id: String { rawValue }
    var caption: String {
        switch self {
        case .all: return "Everything"
        case .pinned: return "Pinned"
        case .unreadable: return "Unreadable"
        }
    }
}

struct WallTab: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    @State private var filter: Hang = .all
    @State private var probe = ""
    @State private var packs: Set<Pack> = []
    @State private var seeking = false
    @State private var pan: CGSize = .zero
    @State private var anchor: CGSize = .zero
    @State private var zoom: CGFloat = 1
    @State private var pinch: CGFloat = 1

    private let cell = CGSize(width: 152, height: 178)
    private let gap: CGFloat = 18

    private var hung: [Scrawl] {
        let shelf: [Scrawl]
        switch filter {
        case .all: shelf = vault.scrawls
        case .pinned: shelf = vault.scrawls.filter(\.pinned)
        case .unreadable: shelf = vault.scrawls.filter(\.unreadable)
        }

        let q = probe.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty || !packs.isEmpty else { return shelf }

        return shelf.filter { s in
            guard packs.isEmpty || packs.contains(s.pack) else { return false }
            guard !q.isEmpty else { return true }
            return s.word.lowercased().contains(q) || (s.artist?.lowercased().contains(q) ?? false)
        }
    }

    private var narrowed: Bool {
        !probe.trimmingCharacters(in: .whitespaces).isEmpty || !packs.isEmpty
    }

    private var topPad: CGFloat { seeking ? 196 : 72 }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Ink.base.ignoresSafeArea()

                if hung.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer(minLength: topPad + 18)
                            EmptyFrame(
                                headline: emptyHead,
                                note: emptyNote,
                                cta: narrowed ? "Clear the search" : (filter == .all ? "Draw something" : "Show everything")
                            ) {
                                if narrowed {
                                    clearSearch()
                                } else if filter == .all {
                                    chrome.bay = .draw
                                } else {
                                    filter = .all
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.bottom, 140)
                    }
                } else {
                    board(in: geo.size)
                }

                bar
            }
        }
    }

    private var emptyHead: String {
        if narrowed { return "No such drawing" }
        return filter == .all ? "Bare wall" : "Nothing here yet"
    }

    private var emptyNote: String {
        if narrowed {
            return "Nothing on this shelf matches that word or those packs. Widen the search and the wall fills back up."
        }
        switch filter {
        case .all: return "Every blind round lands here and stays. Right now the nails are empty."
        case .pinned: return "Pin an exhibit from its page and it shows up on this shelf."
        case .unreadable: return "Drawings you failed to recognise in Recall land here. None so far — suspicious."
        }
    }

    private func board(in size: CGSize) -> some View {
        let cols = 2
        let rows = Int(ceil(Double(hung.count) / Double(cols)))
        let boardW = CGFloat(cols) * cell.width + CGFloat(cols + 1) * gap
        let boardH = CGFloat(rows) * cell.height + CGFloat(rows + 1) * gap + topPad + 18

        return ZStack {
            ForEach(Array(hung.enumerated()), id: \.element.id) { i, s in
                exhibitCard(s)
                    .frame(width: cell.width, height: cell.height)
                    .position(
                        x: gap + cell.width / 2 + CGFloat(i % cols) * (cell.width + gap) + wobbleOffset(s.id).width,
                        y: topPad + gap + cell.height / 2 + CGFloat(i / cols) * (cell.height + gap) + wobbleOffset(s.id).height
                    )
            }
        }
        .frame(width: boardW, height: boardH)
        .scaleEffect(zoom * pinch)
        .offset(x: pan.width + anchor.width, y: pan.height + anchor.height)
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
        .contentShape(Rectangle())
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .onChanged { v in pan = v.translation }
                    .onEnded { v in
                        anchor = clamp(CGSize(width: anchor.width + v.translation.width, height: anchor.height + v.translation.height), board: CGSize(width: boardW, height: boardH), screen: size)
                        pan = .zero
                    },
                MagnificationGesture()
                    .onChanged { v in pinch = v }
                    .onEnded { v in
                        zoom = max(0.5, min(1.4, zoom * v))
                        pinch = 1
                        anchor = clamp(anchor, board: CGSize(width: boardW, height: boardH), screen: size)
                        Bumper.tap(.soft)
                    }
            )
        )
    }

    private func clamp(_ o: CGSize, board: CGSize, screen: CGSize) -> CGSize {
        let w = board.width * zoom, h = board.height * zoom
        let slackX = max(0, w - screen.width) + 40
        let slackY = max(0, h - screen.height) + 120
        return CGSize(
            width: min(40, max(-slackX, o.width)),
            height: min(70, max(-slackY, o.height))
        )
    }

    private func wobbleOffset(_ id: UUID) -> CGSize {
        let h = abs(id.uuidString.hashValue)
        return CGSize(width: CGFloat(h % 17) - 8, height: CGFloat((h / 17) % 21) - 10)
    }

    private func exhibitCard(_ s: Scrawl) -> some View {
        Button {
            Bumper.tap(.light)
            chrome.wall.append(.exhibit(s.id))
        } label: {
            Scrap(tilt: lean(s.id), fill: Ink.soot, edge: s.pinned ? Ink.flare.opacity(0.8) : Ink.bone.opacity(0.2), seed: UInt64(abs(s.id.hashValue % 700)), taped: true) {
                VStack(spacing: 9) {
                    ScrawlView(strokes: s.strokes, color: Ink.bone.opacity(0.92), weight: 1.9, offprint: false)
                        .frame(maxWidth: .infinity)
                        .background(Ink.void.opacity(0.55))
                    VStack(spacing: 3) {
                        Text(s.word.uppercased()).placardStyle(10, Ink.bone, weight: .semibold)
                        Placard(stampLine(s), size: 8, color: s.unreadable ? Ink.flare : Ink.faded)
                    }
                    .frame(height: 30)
                }
                .padding(11)
            }
        }
        .buttonStyle(.plain)
    }

    private func stampLine(_ s: Scrawl) -> String {
        if s.origin == .calibration { return "calibration" }
        if s.unreadable { return "unreadable" }
        if let a = s.artist, s.origin == .bout { return "by \(a)" }
        return DayKey.string(s.bornAt)
    }

    private var bar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(Hang.allCases) { h in
                    Button {
                        Bumper.tap(.light)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            filter = h
                            reframe()
                        }
                    } label: {
                        Chip(text: h.caption, on: filter == h, seed: UInt64(abs(h.rawValue.hashValue % 400)))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: 2)

                Button {
                    Bumper.tap(.light)
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                        seeking.toggle()
                        if !seeking { probe = "" ; packs = [] }
                        reframe()
                    }
                } label: {
                    Shaky { beat in
                        LensGlyph(seed: beat &+ 341)
                            .stroke(
                                seeking || narrowed ? Ink.flare : Ink.faded,
                                style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)
                            )
                            .frame(width: 16, height: 16)
                    }
                    .padding(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Placard("\(hung.count)", size: 12, color: Ink.flare)
            }

            if seeking {
                VStack(spacing: 11) {
                    PlacardField(caption: "Word or signature", text: $probe, limit: 20, seed: 343)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 7) {
                            ForEach(Pack.allCases) { p in
                                Button {
                                    Bumper.tap(.light)
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                        if packs.contains(p) {
                                            packs.remove(p)
                                        } else {
                                            packs.insert(p)
                                        }
                                        reframe()
                                    }
                                } label: {
                                    Chip(text: p.title, on: packs.contains(p), tint: p.stamp, seed: UInt64(abs(p.rawValue.hashValue % 380)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            LinearGradient(colors: [Ink.base, Ink.base, Ink.base.opacity(0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
        .onChange(of: probe) { _ in reframe() }
    }

    private func clearSearch() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
            probe = ""
            packs = []
            reframe()
        }
    }

    private func reframe() {
        anchor = .zero
        pan = .zero
        zoom = 1
    }
}
