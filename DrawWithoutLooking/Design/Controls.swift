import SwiftUI

struct SlabButtonStyle: ButtonStyle {
    var tint: Color = Ink.flare
    var label: Color = Ink.base
    var seed: UInt64 = 11
    var radius: CGFloat = 13
    var tall: CGFloat = 54

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.placard(13, .bold))
            .tracking(2.2)
            .foregroundColor(label)
            .frame(maxWidth: .infinity)
            .frame(height: tall)
            .background(
                Shaky { beat in
                    WobblyRect(radius: radius, seed: beat &+ seed, amp: 1.7).fill(tint)
                }
            )
            .overlay(
                Shaky { beat in
                    WobblyRect(radius: radius, seed: beat &+ seed &+ 3, amp: 2.6)
                        .stroke(tint.opacity(0.5), lineWidth: 1)
                        .offset(x: 2.5, y: -2)
                        .blendMode(.plusLighter)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.955 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { down in
                if down { Bumper.tap(.light) }
            }
    }
}

struct GhostButtonStyle: ButtonStyle {
    var tint: Color = Ink.bone
    var seed: UInt64 = 17
    var tall: CGFloat = 48

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.placard(12, .semibold))
            .tracking(2)
            .foregroundColor(tint.opacity(configuration.isPressed ? 0.6 : 1))
            .frame(maxWidth: .infinity)
            .frame(height: tall)
            .overlay(
                Shaky { beat in
                    WobblyRect(radius: 12, seed: beat &+ seed, amp: 1.5).stroke(tint.opacity(0.4), lineWidth: 1.3)
                }
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct Chip: View {
    let text: String
    var on: Bool
    var tint: Color = Ink.flare
    var seed: UInt64 = 23

    var body: some View {
        Placard(text, size: 10, color: on ? Ink.base : Ink.faded, weight: .semibold)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Shaky { beat in
                    WobblyRect(radius: 9, seed: beat &+ seed, amp: 1.3)
                        .fill(on ? tint : Color.clear)
                }
            )
            .overlay(
                Shaky { beat in
                    WobblyRect(radius: 9, seed: beat &+ seed, amp: 1.3)
                        .stroke(on ? tint : Ink.faded.opacity(0.45), lineWidth: 1.2)
                }
            )
    }
}

struct PlacardField: View {
    let caption: String
    @Binding var text: String
    var limit: Int = 14
    var seed: UInt64 = 41
    @FocusState private var hot: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Placard(caption, size: 10, color: hot ? Ink.flare : Ink.faded)
            TextField("", text: $text)
                .focused($hot)
                .font(.slug(24))
                .tracking(-0.5)
                .foregroundColor(Ink.bone)
                .tint(Ink.flare)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onChange(of: text) { v in
                    if v.count > limit { text = String(v.prefix(limit)) }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    Shaky { beat in
                        WobblyRect(radius: 11, seed: beat &+ seed, amp: 1.5).fill(Ink.smoke)
                    }
                )
                .overlay(
                    Shaky { beat in
                        WobblyRect(radius: 11, seed: beat &+ seed, amp: 1.5)
                            .stroke(hot ? Ink.flare : Ink.bone.opacity(0.25), lineWidth: hot ? 1.7 : 1.2)
                    }
                )
        }
    }
}

struct SwitchRow: View {
    let title: String
    let note: String
    @Binding var on: Bool
    var seed: UInt64 = 61

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.7)) { on.toggle() }
            Bumper.tap(.light)
        } label: {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title.uppercased()).placardStyle(12, Ink.bone, weight: .semibold)
                    Text(note).font(.system(size: 12.5)).foregroundColor(Ink.faded).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                ZStack(alignment: on ? .trailing : .leading) {
                    Shaky { beat in
                        WobblyRect(radius: 11, seed: beat &+ seed, amp: 1.4)
                            .stroke(on ? Ink.flare : Ink.faded.opacity(0.5), lineWidth: 1.3)
                    }
                    Shaky { beat in
                        WobblyBlob(seed: beat &+ seed &+ 5, amp: 1.6)
                            .fill(on ? Ink.flare : Ink.faded)
                            .frame(width: 17, height: 17)
                            .padding(3)
                    }
                }
                .frame(width: 46, height: 24)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct Stat: View {
    let value: String
    let caption: String
    var tint: Color = Ink.bone

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value).font(.slug(30)).tracking(-1).foregroundColor(tint)
            Placard(caption, size: 9)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyFrame: View {
    let headline: String
    let note: String
    var cta: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Shaky { beat in
                ZStack {
                    WobblyRect(radius: 8, seed: beat &+ 71, amp: 2.4)
                        .stroke(Ink.bone.opacity(0.22), style: StrokeStyle(lineWidth: 1.4, dash: [7, 6]))
                    CrossGlyph(seed: beat &+ 72)
                        .stroke(Ink.bone.opacity(0.1), lineWidth: 1.2)
                        .padding(34)
                }
                .frame(width: 132, height: 108)
            }
            VStack(spacing: 9) {
                Slug(text: headline, size: 21)
                Text(note)
                    .font(.system(size: 13.5))
                    .foregroundColor(Ink.faded)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 260)
            }
            if let cta, let action {
                Button(cta.uppercased(), action: action)
                    .buttonStyle(SlabButtonStyle(tint: Ink.flare, seed: 73, tall: 48))
                    .frame(width: 220)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 44)
        .frame(maxWidth: .infinity)
    }
}
