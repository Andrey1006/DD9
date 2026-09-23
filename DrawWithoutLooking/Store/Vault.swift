import Combine
import SwiftUI

final class Vault: ObservableObject {
    static let shared = Vault()

    @Published private(set) var scrawls: [Scrawl] = []
    @Published private(set) var bouts: [Bout] = []
    @Published private(set) var days: [String: Int] = [:]
    @Published var nib: Nib? {
        didSet { flush(nib, to: Key.nib) }
    }

    private let d = UserDefaults.standard

    private enum Key {
        static let schema = "dwl.schema"
        static let scrawls = "dwl.scrawls"
        static let nib = "dwl.nib"
        static let bouts = "dwl.bouts"
        static let days = "dwl.days"
        static let sown = "dwl.demoSown"
    }

    private static let schema = 2

    private let curingHours: TimeInterval = 36

    private init() {
        let stored = d.integer(forKey: Key.schema)
        if stored != 0 && stored != Self.schema {

            wipeStorage()
        }
        d.set(Self.schema, forKey: Key.schema)

        scrawls = load([Scrawl].self, Key.scrawls) ?? []
        bouts = load([Bout].self, Key.bouts) ?? []
        days = load([String: Int].self, Key.days) ?? [:]
        nib = load(Nib.self, Key.nib)

        if !d.bool(forKey: Key.sown) {
            sowDemo()
        }
    }

    func keep(_ s: Scrawl) {
        scrawls.insert(s, at: 0)
        flushScrawls()
        if s.origin != .calibration { logDay() }
    }

    func toss(_ id: UUID) {
        scrawls.removeAll { $0.id == id }
        for i in bouts.indices {
            bouts[i].scrawlIDs.removeAll { $0 == id }
        }
        flushScrawls()
        flush(bouts, to: Key.bouts)
    }

    func flip(_ id: UUID) {
        guard let i = scrawls.firstIndex(where: { $0.id == id }) else { return }
        scrawls[i].pinned.toggle()
        flushScrawls()
    }

    func noteRecall(_ id: UUID, guessed: String, hit: Bool) {
        guard let i = scrawls.firstIndex(where: { $0.id == id }) else { return }
        scrawls[i].recalls.append(RecallShot(at: Date(), guessed: guessed, hit: hit))
        flushScrawls()
    }

    func scrawl(_ id: UUID) -> Scrawl? {
        scrawls.first { $0.id == id }
    }

    func file(_ b: Bout, drawings: [Scrawl]) {
        scrawls.insert(contentsOf: drawings, at: 0)
        bouts.insert(b, at: 0)
        flushScrawls()
        flush(bouts, to: Key.bouts)
        logDay(drawings.count)
    }

    private func logDay(_ n: Int = 1) {
        let k = DayKey.string(Date())
        days[k, default: 0] += n
        flush(days, to: Key.days)
    }

    var streak: Int {
        let cal = Calendar.current
        var probe = Date()

        if days[DayKey.string(probe)] == nil {
            guard let back = cal.date(byAdding: .day, value: -1, to: probe), days[DayKey.string(back)] != nil else { return 0 }
            probe = back
        }
        var n = 0
        while days[DayKey.string(probe)] != nil {
            n += 1
            guard let back = cal.date(byAdding: .day, value: -1, to: probe) else { break }
            probe = back
        }
        return n
    }

    var roundsToday: Int { days[DayKey.string(Date())] ?? 0 }

    var drift: Drift {
        DriftReader.rolling(scrawls.filter { !$0.isBlank }, seed: nib?.calibration)
    }

    var legibility: Double? {
        let shots = scrawls.flatMap(\.recalls)
        guard !shots.isEmpty else { return nil }
        return Double(shots.filter(\.hit).count) / Double(shots.count)
    }

    func legibility(of pack: Pack) -> Double? {
        let shots = scrawls.filter { $0.pack == pack }.flatMap(\.recalls)
        guard !shots.isEmpty else { return nil }
        return Double(shots.filter(\.hit).count) / Double(shots.count)
    }

    func recallDeck(limit: Int = 12) -> [Scrawl] {
        let cutoff = Date().addingTimeInterval(-curingHours * 3600)
        return testable.filter { $0.bornAt < cutoff }.sorted {
            if $0.recalls.count != $1.recalls.count { return $0.recalls.count < $1.recalls.count }
            return $0.bornAt < $1.bornAt
        }.prefix(limit).map { $0 }
    }

    var curing: Int {
        let cutoff = Date().addingTimeInterval(-curingHours * 3600)
        return testable.filter { $0.bornAt >= cutoff }.count
    }

    private var testable: [Scrawl] {
        scrawls.filter { !$0.isBlank && $0.origin != .calibration }
    }

    var recentWords: [String] {
        scrawls.prefix(8).map(\.word)
    }

    func ledger() -> Ledger {
        Ledger(schema: Self.schema, madeAt: Date(), nib: nib, scrawls: scrawls, bouts: bouts, days: days)
    }

    @discardableResult
    func swallow(_ ledger: Ledger) -> Int {
        let known = Set(scrawls.map(\.id))
        let fresh = ledger.scrawls.filter { !known.contains($0.id) }
        if !fresh.isEmpty {
            scrawls.append(contentsOf: fresh)
            scrawls.sort { $0.bornAt > $1.bornAt }
        }

        let filed = Set(bouts.map(\.id))
        let newBouts = ledger.bouts.filter { !filed.contains($0.id) }
        if !newBouts.isEmpty {
            bouts.append(contentsOf: newBouts)
            bouts.sort { $0.at > $1.at }
        }

        for (day, count) in ledger.days {
            days[day] = max(days[day] ?? 0, count)
        }

        if nib == nil { nib = ledger.nib }

        flushScrawls()
        flush(bouts, to: Key.bouts)
        flush(days, to: Key.days)
        return fresh.count
    }

    func burnEverything() {
        wipeStorage()
        scrawls = []
        bouts = []
        days = [:]
        nib = nil
        d.set(Self.schema, forKey: Key.schema)
    }

    private func wipeStorage() {
        [Key.scrawls, Key.nib, Key.bouts, Key.days, Key.sown].forEach(d.removeObject(forKey:))
    }

    private func sowDemo() {
        scrawls = DemoWall.build()
        days = DemoWall.days()
        flushScrawls()
        flush(days, to: Key.days)
        d.set(true, forKey: Key.sown)
    }

    private func flushScrawls() { flush(scrawls, to: Key.scrawls) }

    private func flush<T: Encodable>(_ value: T?, to key: String) {
        guard let value else {
            d.removeObject(forKey: key)
            return
        }
        guard let data = try? JSONEncoder().encode(value) else { return }
        d.set(data, forKey: key)
    }

    private func load<T: Decodable>(_ type: T.Type, _ key: String) -> T? {
        guard let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
