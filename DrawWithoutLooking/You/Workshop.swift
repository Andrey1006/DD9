
import SwiftUI
import UniformTypeIdentifiers

struct Workshop: View {
    @EnvironmentObject private var vault: Vault
    @EnvironmentObject private var chrome: Chrome

    @State private var policy = false
    @State private var burning = false
    @State private var handle = ""
    @State private var exported: Printed?
    @State private var importing = false
    @State private var archiveNote: String?

    private var nib: Nib { vault.nib ?? .fresh(handle: "Anon") }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    Slug(text: "Workshop", size: 32)
                        .padding(.top, 4)

                    signature
                    tempoBlock
                    switches
                    policyRow
                    archiveBlock
                    dangerRow
                    colophon
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 60)
            }
        }
        .pushedScreen("You") { chrome.you.removeLast() }
        .onAppear { handle = nib.handle }
        .sheet(item: $exported) { done in
            ActivityBoard(items: [done.url])
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            readArchive(result)
        }
        .sheet(isPresented: $policy) {
            PrivacyPolicySheet()
                .presentationDetents([.large])
        }
        .alert("Burn everything?", isPresented: $burning) {
            Button("Cancel", role: .cancel) {}
            Button("Burn it", role: .destructive) { burn() }
        } message: {
            Text("Every drawing, bout, streak and setting is deleted — including the six we shipped with. You will start from the calibration circle again.")
        }
    }

    private var signature: some View {
        VStack(alignment: .leading, spacing: 11) {
            Placard("the signature", size: 9, color: Ink.flare)
            PlacardField(caption: "Sign the wall as", text: $handle, seed: 517)
            Text("Goes on every new drawing and on your seat in a bout. Work already on the wall keeps the name it was signed with.")
                .font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(3)
        }
        .onChange(of: handle) { v in sign(v) }
    }

    private func sign(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != nib.handle, var n = vault.nib else { return }
        n.handle = trimmed
        vault.nib = n
    }

    private var tempoBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Placard("round length", size: 9, color: Ink.flare)
            HStack(spacing: 8) {
                ForEach(Tempo.allCases) { t in
                    Button {
                        Bumper.tap(.light)
                        var n = nib
                        n.seconds = t.rawValue
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) { vault.nib = n }
                    } label: {
                        VStack(spacing: 5) {
                            Text("\(t.rawValue)")
                                .font(.placard(22, .light))
                                .foregroundColor(nib.seconds == t.rawValue ? Ink.base : Ink.faded)
                            Placard(t.title, size: 8, color: nib.seconds == t.rawValue ? Ink.base : Ink.faded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Shaky { beat in
                                WobblyRect(radius: 11, seed: beat &+ UInt64(t.rawValue), amp: 1.5)
                                    .fill(nib.seconds == t.rawValue ? Ink.flare : Color.clear)
                            }
                        )
                        .overlay(
                            Shaky { beat in
                                WobblyRect(radius: 11, seed: beat &+ UInt64(t.rawValue), amp: 1.5)
                                    .stroke(nib.seconds == t.rawValue ? Ink.flare : Ink.bone.opacity(0.2), lineWidth: 1.2)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var switches: some View {
        VStack(alignment: .leading, spacing: 20) {
            Placard("the rig", size: 9, color: Ink.flare)

            SwitchRow(title: "Pitch guide", note: "A tone follows your finger: height for up-down, stereo for left-right.", on: bind(\.sonar), seed: 521)
            SwitchRow(title: "Haptics", note: "Edge ticks, stroke lifts, verdicts.", on: bind(\.haptics), seed: 523)
            SwitchRow(title: "Trust mode", note: "Shows the line while you draw and asks you to turn the phone away yourself.", on: bind(\.trustMode), seed: 525)
            SwitchRow(title: "Steady hand", note: "Freezes the shaking interface. Everything stays crooked, it just stops moving.", on: bind(\.steadyHand), seed: 527)
        }
    }

    private func bind(_ path: WritableKeyPath<Nib, Bool>) -> Binding<Bool> {
        Binding(
            get: { vault.nib?[keyPath: path] ?? false },
            set: { v in
                guard var n = vault.nib else { return }
                n[keyPath: path] = v
                vault.nib = n
            }
        )
    }

    private var policyRow: some View {
        Button {
            Bumper.tap(.light)
            policy = true
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Placard("privacy policy", size: 11, color: Ink.bone, weight: .semibold)
                    Text("Nothing leaves this phone. Read the long version anyway.")
                        .font(.system(size: 12)).foregroundColor(Ink.faded)
                }
                Spacer(minLength: 0)
                Shaky { beat in
                    ArrowGlyph(seed: beat &+ 531)
                        .stroke(Ink.faded, style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
                        .frame(width: 18, height: 12)
                }
            }
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .hairline(seed: 533)
        }
        .buttonStyle(.plain)
    }

    private var archiveBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Placard("the archive", size: 9, color: Ink.cobalt)
            Text("Everything lives on this phone and nowhere else — delete the app and it goes with it. Write the whole vault out to a file, or read one back in.")
                .font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(3)

            HStack(spacing: 10) {
                Button("Export") { writeArchive() }
                    .buttonStyle(GhostButtonStyle(tint: Ink.bone, seed: 541, tall: 48))

                Button("Import") {
                    Bumper.tap(.light)
                    importing = true
                }
                .buttonStyle(GhostButtonStyle(tint: Ink.cobalt, seed: 543, tall: 48))
            }

            if let archiveNote {
                Placard(archiveNote, size: 9)
                    .transition(.opacity)
            }
        }
    }

    private func writeArchive() {
        Bumper.tap(.light)
        guard let url = Archivist.file(vault.ledger()) else {
            mutter("The archive would not write. Try again.")
            return
        }
        archiveNote = nil
        exported = Printed(url: url)
    }

    private func readArchive(_ result: Result<URL, Error>) {
        switch result {
        case .failure:
            mutter("That file never opened.")
        case .success(let url):
            guard let ledger = Archivist.read(url) else {
                Bumper.verdict(false)
                mutter("That is not an archive this app wrote.")
                return
            }
            let added = vault.swallow(ledger)
            handle = nib.handle
            Bumper.verdict(true)
            mutter(added == 0
                   ? "nothing new in there — every drawing was already yours"
                   : "\(added) \(added == 1 ? "drawing" : "drawings") joined the wall")
        }
    }

    private func mutter(_ text: String) {
        withAnimation(.easeOut(duration: 0.25)) { archiveNote = text }
    }

    private var dangerRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            Placard("scorched earth", size: 9, color: Ink.flare)
            Text("\(vault.scrawls.count) drawings, \(vault.bouts.count) bouts and \(vault.scrawls.flatMap(\.recalls).count) recall tests are stored on this device.")
                .font(.system(size: 12.5)).foregroundColor(Ink.faded).lineSpacing(3)
            Button("Burn everything") {
                Bumper.tap(.rigid)
                burning = true
            }
            .buttonStyle(SlabButtonStyle(tint: Ink.flare, label: Ink.base, seed: 535, tall: 52))
        }
    }

    private var colophon: some View {
        VStack(alignment: .leading, spacing: 5) {
            Placard("ink hand diary", size: 8)
            Placard("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") · offline, always", size: 8, color: Ink.faded.opacity(0.6))
        }
        .padding(.top, 8)
    }

    private func burn() {
        chrome.you.removeAll()
        chrome.wall.removeAll()
        chrome.recall.removeAll()
        chrome.bout.removeAll()
        chrome.curtain = false
        chrome.bay = .draw
        Bumper.verdict(false)
        vault.burnEverything()
    }
}
