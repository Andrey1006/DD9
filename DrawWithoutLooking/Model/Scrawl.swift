import Foundation
import CoreGraphics

struct Dab: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var t: Double
}

struct Stroke: Codable, Equatable {
    var dabs: [Dab]

    var span: ClosedRange<Double> {
        guard let a = dabs.first?.t, let b = dabs.last?.t else { return 0...0 }
        return a...max(a, b)
    }
}

enum Bet: Int, Codable, CaseIterable {
    case disaster = 0
    case fine = 1
    case masterpiece = 2

    var call: String {
        switch self {
        case .disaster: return "Total wreck"
        case .fine: return "Passable"
        case .masterpiece: return "Masterpiece"
        }
    }

    var mark: String {
        switch self {
        case .disaster: return "!!"
        case .fine: return "~"
        case .masterpiece: return "★"
        }
    }
}

struct RecallShot: Codable, Equatable {
    var at: Date
    var guessed: String
    var hit: Bool
}

enum Origin: String, Codable {
    case solo
    case bout
    case calibration
}

struct Scrawl: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var word: String
    var pack: Pack
    var bornAt: Date
    var strokes: [Stroke]
    var seconds: Int
    var bet: Bet?
    var recalls: [RecallShot] = []
    var pinned: Bool = false
    var origin: Origin = .solo
    var artist: String?
    var solved: Bool?

    var isBlank: Bool { strokes.allSatisfy { $0.dabs.count < 2 } }

    var unreadable: Bool {
        guard !recalls.isEmpty else { return false }
        return recalls.filter(\.hit).isEmpty
    }

    var legibility: Double? {
        guard !recalls.isEmpty else { return nil }
        return Double(recalls.filter(\.hit).count) / Double(recalls.count)
    }

    var dabCount: Int { strokes.reduce(0) { $0 + $1.dabs.count } }
}
