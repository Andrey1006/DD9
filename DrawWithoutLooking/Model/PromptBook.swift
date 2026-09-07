import SwiftUI

enum Pack: String, Codable, CaseIterable, Identifiable {
    case animals, kitchen, absurd, jobs, horror, tech, tales

    var id: String { rawValue }

    var title: String {
        switch self {
        case .animals: return "Creatures"
        case .kitchen: return "Kitchen"
        case .absurd: return "Absurd"
        case .jobs: return "Trades"
        case .horror: return "Dread"
        case .tech: return "Gadgets"
        case .tales: return "Tales"
        }
    }

    var blurb: String {
        switch self {
        case .animals: return "Legs, beaks, too many tails"
        case .kitchen: return "Things that live on a counter"
        case .absurd: return "Nouns that should not exist"
        case .jobs: return "People and what they hold"
        case .horror: return "Draw it before it draws you"
        case .tech: return "Boxes with buttons"
        case .tales: return "Everyone knows the shape"
        }
    }

    var stamp: Color {
        switch self {
        case .animals, .absurd, .horror: return Ink.flare
        case .kitchen, .jobs, .tech, .tales: return Ink.cobalt
        }
    }
}

struct Prompt: Equatable {
    let word: String
    let pack: Pack
    let heat: Int
}

enum PromptBook {
    static let all: [Prompt] = [
        .init(word: "octopus", pack: .animals, heat: 2),
        .init(word: "pelican", pack: .animals, heat: 3),
        .init(word: "hedgehog", pack: .animals, heat: 2),
        .init(word: "snail", pack: .animals, heat: 1),
        .init(word: "giraffe", pack: .animals, heat: 1),
        .init(word: "bat", pack: .animals, heat: 2),
        .init(word: "crab", pack: .animals, heat: 1),
        .init(word: "moose", pack: .animals, heat: 3),
        .init(word: "penguin", pack: .animals, heat: 1),
        .init(word: "jellyfish", pack: .animals, heat: 2),
        .init(word: "rooster", pack: .animals, heat: 3),
        .init(word: "sloth", pack: .animals, heat: 3),

        .init(word: "toaster", pack: .kitchen, heat: 1),
        .init(word: "kettle", pack: .kitchen, heat: 1),
        .init(word: "whisk", pack: .kitchen, heat: 2),
        .init(word: "colander", pack: .kitchen, heat: 3),
        .init(word: "corkscrew", pack: .kitchen, heat: 3),
        .init(word: "fried egg", pack: .kitchen, heat: 1),
        .init(word: "pepper mill", pack: .kitchen, heat: 2),
        .init(word: "cutting board", pack: .kitchen, heat: 1),
        .init(word: "blender", pack: .kitchen, heat: 2),
        .init(word: "teabag", pack: .kitchen, heat: 2),
        .init(word: "muffin tray", pack: .kitchen, heat: 3),

        .init(word: "sad banana", pack: .absurd, heat: 2),
        .init(word: "cactus in a hat", pack: .absurd, heat: 3),
        .init(word: "running toilet", pack: .absurd, heat: 3),
        .init(word: "hamster mayor", pack: .absurd, heat: 3),
        .init(word: "cloud on a leash", pack: .absurd, heat: 3),
        .init(word: "melting clock", pack: .absurd, heat: 2),
        .init(word: "toothy sofa", pack: .absurd, heat: 3),
        .init(word: "sock puppet", pack: .absurd, heat: 2),
        .init(word: "upside-down tree", pack: .absurd, heat: 2),
        .init(word: "shy volcano", pack: .absurd, heat: 3),

        .init(word: "welder", pack: .jobs, heat: 3),
        .init(word: "barber", pack: .jobs, heat: 2),
        .init(word: "postman", pack: .jobs, heat: 2),
        .init(word: "beekeeper", pack: .jobs, heat: 3),
        .init(word: "chef", pack: .jobs, heat: 1),
        .init(word: "diver", pack: .jobs, heat: 2),
        .init(word: "farmer", pack: .jobs, heat: 2),
        .init(word: "pilot", pack: .jobs, heat: 2),
        .init(word: "lifeguard", pack: .jobs, heat: 3),
        .init(word: "clown", pack: .jobs, heat: 1),

        .init(word: "haunted lamp", pack: .horror, heat: 3),
        .init(word: "coffin", pack: .horror, heat: 1),
        .init(word: "spider web", pack: .horror, heat: 1),
        .init(word: "screaming skull", pack: .horror, heat: 2),
        .init(word: "black cat", pack: .horror, heat: 2),
        .init(word: "grave", pack: .horror, heat: 1),
        .init(word: "one big eye", pack: .horror, heat: 2),
        .init(word: "creaking door", pack: .horror, heat: 3),
        .init(word: "witch hat", pack: .horror, heat: 1),
        .init(word: "swamp hand", pack: .horror, heat: 3),

        .init(word: "headphones", pack: .tech, heat: 1),
        .init(word: "game pad", pack: .tech, heat: 2),
        .init(word: "old tv", pack: .tech, heat: 1),
        .init(word: "satellite", pack: .tech, heat: 3),
        .init(word: "printer", pack: .tech, heat: 2),
        .init(word: "camera", pack: .tech, heat: 2),
        .init(word: "router", pack: .tech, heat: 3),
        .init(word: "floppy disk", pack: .tech, heat: 1),
        .init(word: "drone", pack: .tech, heat: 2),
        .init(word: "wall socket", pack: .tech, heat: 1),

        .init(word: "beanstalk", pack: .tales, heat: 2),
        .init(word: "gingerbread man", pack: .tales, heat: 2),
        .init(word: "glass slipper", pack: .tales, heat: 2),
        .init(word: "dragon", pack: .tales, heat: 2),
        .init(word: "magic lamp", pack: .tales, heat: 1),
        .init(word: "wolf in a bonnet", pack: .tales, heat: 3),
        .init(word: "castle", pack: .tales, heat: 1),
        .init(word: "mermaid", pack: .tales, heat: 2),
        .init(word: "golden key", pack: .tales, heat: 1),
        .init(word: "talking mirror", pack: .tales, heat: 3)
    ]

    static func pool(_ packs: [Pack]) -> [Prompt] {
        let wanted = packs.isEmpty ? Pack.allCases : packs
        return all.filter { wanted.contains($0.pack) }
    }

    static func pick(from packs: [Pack], avoiding recent: [String] = []) -> Prompt {
        let pool = self.pool(packs)
        let fresh = pool.filter { !recent.contains($0.word) }
        return (fresh.isEmpty ? pool : fresh).randomElement() ?? all[0]
    }

    static func ofTheDay(_ packs: [Pack], on day: Date = Date()) -> Prompt {
        let pool = self.pool(packs)
        guard !pool.isEmpty else { return all[0] }
        let key = DayKey.string(day) + packs.map(\.rawValue).sorted().joined()
        var rng = Seeded(word: key)
        return pool[rng.next(0..<pool.count)]
    }

    static func decoys(for word: String, packs: [Pack], count: Int = 3) -> [String] {
        var rng = Seeded(word: word + "decoy")
        var bag = pool(packs).map(\.word).filter { $0 != word }
        if bag.count < count { bag = all.map(\.word).filter { $0 != word } }
        var out: [String] = []
        while out.count < count, !bag.isEmpty {
            out.append(bag.remove(at: rng.next(0..<bag.count)))
        }
        return out
    }

    static func pack(of word: String) -> Pack {
        all.first { $0.word == word }?.pack ?? .absurd
    }
}

enum DayKey {
    static func string(_ d: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
