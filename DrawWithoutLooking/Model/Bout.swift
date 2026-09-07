import Foundation

struct Player: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var score: Int = 0
}

struct Bout: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var at: Date
    var players: [Player]
    var scrawlIDs: [UUID]
    var pack: Pack

    var champion: Player? {
        players.max { $0.score < $1.score }
    }

    var tally: String {
        players.sorted { $0.score > $1.score }.map { "\($0.name) \($0.score)" }.joined(separator: " · ")
    }
}
