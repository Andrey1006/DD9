
import CoreGraphics
import Foundation

enum DemoWall {
    private struct Sketch {
        let word: String
        let daysAgo: Int
        let bet: Bet
        let seconds: Int
    }

    private static let plan: [Sketch] = [
        .init(word: "octopus", daysAgo: 0, bet: .fine, seconds: 15),
        .init(word: "toaster", daysAgo: 1, bet: .masterpiece, seconds: 15),
        .init(word: "pelican", daysAgo: 2, bet: .disaster, seconds: 10),
        .init(word: "haunted lamp", daysAgo: 4, bet: .fine, seconds: 15),
        .init(word: "beekeeper", daysAgo: 5, bet: .disaster, seconds: 25),
        .init(word: "floppy disk", daysAgo: 7, bet: .masterpiece, seconds: 15)
    ]

    static func build() -> [Scrawl] {
        plan.enumerated().map { idx, s in
            var rng = Seeded(word: s.word)
            var item = Scrawl(
                word: s.word,
                pack: PromptBook.pack(of: s.word),
                bornAt: back(s.daysAgo, hour: 19 + idx % 3),
                strokes: scribble(&rng, seconds: s.seconds),
                seconds: s.seconds,
                bet: s.bet,
                origin: .solo
            )

            if s.word == "pelican" {

                item.recalls = [
                    RecallShot(at: back(1), guessed: "moose", hit: false),
                    RecallShot(at: back(0), guessed: "crab", hit: false)
                ]
            }
            if s.word == "toaster" {
                item.recalls = [RecallShot(at: back(0), guessed: "toaster", hit: true)]
                item.pinned = true
            }
            if s.word == "floppy disk" {
                item.recalls = [RecallShot(at: back(2), guessed: "floppy disk", hit: true)]
            }
            return item
        }
    }

    static func days() -> [String: Int] {
        var out: [String: Int] = [:]
        for s in plan {
            out[DayKey.string(back(s.daysAgo)), default: 0] += 1
        }
        return out
    }

    private static func back(_ days: Int, hour: Int = 20) -> Date {
        let cal = Calendar.current
        let day = cal.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return cal.date(bySettingHour: min(23, hour), minute: 12, second: 0, of: day) ?? day
    }

    private static func scribble(_ rng: inout Seeded, seconds: Int) -> [Stroke] {
        let strokeCount = rng.next(2..<5)
        var strokes: [Stroke] = []
        var clock = 0.4

        for _ in 0..<strokeCount {
            var x = rng.spread(0.3, 0.7)
            var y = rng.spread(0.28, 0.68)
            var heading = rng.spread(0, .pi * 2)
            var turn = rng.spread(-0.22, 0.22)
            let steps = rng.next(22..<58)
            var dabs: [Dab] = []

            for _ in 0..<steps {
                let step = rng.spread(0.012, 0.032)
                heading += turn
                turn += rng.spread(-0.09, 0.09)
                turn = max(-0.34, min(0.34, turn))
                x += cos(heading) * step
                y += sin(heading) * step

                if x < 0.04 || x > 0.96 { heading = .pi - heading; x = max(0.04, min(0.96, x)) }
                if y < 0.04 || y > 0.96 { heading = -heading; y = max(0.04, min(0.96, y)) }
                clock += 0.028
                dabs.append(Dab(x: x, y: y, t: clock))
            }
            strokes.append(Stroke(dabs: dabs))
            clock += rng.spread(0.25, 0.8)
            if clock > Double(seconds) - 0.3 { break }
        }
        return strokes
    }
}
