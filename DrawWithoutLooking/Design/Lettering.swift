
import SwiftUI

extension Font {
    static func slug(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func placard(_ size: CGFloat, _ weight: Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension Text {
    func slugStyle(_ size: CGFloat, _ color: Color = Ink.bone) -> Text {
        font(.slug(size)).tracking(-size * 0.035).foregroundColor(color)
    }

    func placardStyle(_ size: CGFloat, _ color: Color = Ink.faded, weight: Font.Weight = .medium) -> Text {
        font(.placard(size, weight)).tracking(size * 0.14).foregroundColor(color)
    }
}

struct Placard: View {
    let text: String
    var size: CGFloat = 11
    var color: Color = Ink.faded
    var weight: Font.Weight = .medium

    init(_ text: String, size: CGFloat = 11, color: Color = Ink.faded, weight: Font.Weight = .medium) {
        self.text = text
        self.size = size
        self.color = color
        self.weight = weight
    }

    var body: some View {
        Text(text.uppercased()).placardStyle(size, color, weight: weight)
    }
}

struct Slug: View {
    let text: String
    var size: CGFloat = 30
    var color: Color = Ink.bone

    var body: some View {
        Text(text.uppercased()).slugStyle(size, color)
    }
}
