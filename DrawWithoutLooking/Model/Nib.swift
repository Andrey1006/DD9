
import Foundation

struct Nib: Codable, Equatable {
    var handle: String
    var packs: [Pack]
    var seconds: Int
    var haptics: Bool
    var sonar: Bool
    var steadyHand: Bool
    var trustMode: Bool
    var since: Date
    var calibration: Drift?

    static func fresh(handle: String) -> Nib {
        Nib(
            handle: handle,
            packs: [.animals, .kitchen],
            seconds: 15,
            haptics: true,
            sonar: true,
            steadyHand: false,
            trustMode: false,
            since: Date(),
            calibration: nil
        )
    }
}

enum Tempo: Int, CaseIterable, Identifiable {
    case rush = 10
    case standard = 15
    case slow = 25

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .rush: return "Rush"
        case .standard: return "Standard"
        case .slow: return "Patient"
        }
    }

    var blurb: String {
        switch self {
        case .rush: return "No time to think. Pure instinct."
        case .standard: return "Enough for a body and two legs."
        case .slow: return "You will run out of ideas first."
        }
    }
}
