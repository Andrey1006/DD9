
import SwiftUI

enum Ink {
    static let base = Color(rgb: 0x0B0A09)
    static let soot = Color(rgb: 0x14120F)
    static let smoke = Color(rgb: 0x231E18)
    static let bone = Color(rgb: 0xEDE4D2)
    static let faded = Color(rgb: 0x7E766A)
    static let flare = Color(rgb: 0xFF4A17)
    static let cobalt = Color(rgb: 0x5A67FF)

    static let void = Color(rgb: 0x000000)
}

extension Color {
    init(rgb: UInt32) {
        self.init(
            .sRGB,
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255,
            opacity: 1
        )
    }
}
