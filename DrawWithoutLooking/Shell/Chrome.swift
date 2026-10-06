
import Combine
import SwiftUI

enum Bay: Int, CaseIterable, Identifiable {
    case wall, recall, draw, bout, you

    var id: Int { rawValue }

    var caption: String {
        switch self {
        case .wall: return "Wall"
        case .recall: return "Recall"
        case .draw: return "Draw"
        case .bout: return "Bout"
        case .you: return "You"
        }
    }
}

enum WallRoute: Hashable { case exhibit(UUID) }
enum RecallRoute: Hashable { case report }
enum BoutRoute: Hashable { case archive }
enum YouRoute: Hashable { case settings }

final class Chrome: ObservableObject {
    @Published var bay: Bay = .draw
    @Published var wall: [WallRoute] = []
    @Published var recall: [RecallRoute] = []
    @Published var bout: [BoutRoute] = []
    @Published var you: [YouRoute] = []

    @Published var curtain = false

    var deep: Bool {
        curtain || !wall.isEmpty || !recall.isEmpty || !bout.isEmpty || !you.isEmpty
    }

    func openExhibit(_ id: UUID) {
        bay = .wall
        wall = [.exhibit(id)]
    }
}
