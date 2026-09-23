import Foundation

struct Ledger: Codable {
    var schema: Int
    var madeAt: Date
    var nib: Nib?
    var scrawls: [Scrawl]
    var bouts: [Bout]
    var days: [String: Int]
}

enum Archivist {
    static func encode(_ ledger: Ledger) -> Data? {
        let coder = JSONEncoder()
        coder.dateEncodingStrategy = .iso8601
        coder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? coder.encode(ledger)
    }

    static func decode(_ data: Data) -> Ledger? {
        let coder = JSONDecoder()
        coder.dateDecodingStrategy = .iso8601
        return try? coder.decode(Ledger.self, from: data)
    }

    static func file(_ ledger: Ledger) -> URL? {
        guard let data = encode(ledger) else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("blind-archive-\(DayKey.string(ledger.madeAt)).json")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    static func read(_ url: URL) -> Ledger? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return decode(data)
    }
}
