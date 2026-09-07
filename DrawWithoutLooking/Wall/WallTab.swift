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
    @State private var pan: CGSize = .zero
    @State private var anchor: CGSize = .zero
    @State private var zoom: CGFloat = 1
    @State private var pinch: CGFloat = 1

    private let cell = CGSize(width: 152, height: 178)
    private let gap: CGFloat = 18

    private var hung: [Scrawl] {
        switch filter {
        case .all: return vault.scrawls
        case .pinned: return vault.scrawls.filter(\.pinned)
        case .unreadable: return vault.scrawls.filter(\.unreadable)
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Ink.base.ignoresSafeArea()

                if hung.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack {
                            Spacer(minLength: 90)
                            EmptyFrame(
                                headline: filter == .all ? "Bare wall" : "Nothing here yet",
                                note: emptyNote,
                                cta: filter == .all ? "Draw something" : "Show everything"
                            ) {
                                filter == .all ? (chrome.bay = .draw) : (filter = .all)
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

    private var emptyNote: String {
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
        let boardH = CGFloat(rows) * cell.height + CGFloat(rows + 1) * gap + 90

        return ZStack {
            ForEach(Array(hung.enumerated()), id: \.element.id) { i, s in
                exhibitCard(s)
                    .frame(width: cell.width, height: cell.height)
                    .position(
                        x: gap + cell.width / 2 + CGFloat(i % cols) * (cell.width + gap) + wobbleOffset(s.id).width,
                        y: 72 + gap + cell.height / 2 + CGFloat(i / cols) * (cell.height + gap) + wobbleOffset(s.id).height
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
        HStack(spacing: 8) {
            ForEach(Hang.allCases) { h in
                Button {
                    Bumper.tap(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        filter = h
                        anchor = .zero
                        zoom = 1
                    }
                } label: {
                    Chip(text: h.caption, on: filter == h, seed: UInt64(abs(h.rawValue.hashValue % 400)))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Placard("\(hung.count)", size: 12, color: Ink.flare)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            LinearGradient(colors: [Ink.base, Ink.base, Ink.base.opacity(0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        )
    }
}
