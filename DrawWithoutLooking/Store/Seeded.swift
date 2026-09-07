import Foundation

struct Seeded: RandomNumberGenerator {
    private var state: UInt64

    init(_ seed: UInt64) {
        state = seed == 0 ? 0x4D595DF4D0F33173 : seed
    }

    init(word: String) {
        var h: UInt64 = 0xCBF29CE484222325
        for b in word.utf8 {
            h ^= UInt64(b)
            h = h &* 0x100000001B3
        }
        self.init(h)
    }

    mutating func next() -> UInt64 {
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545F4914F6CDD1D
    }

    mutating func next(_ range: Range<Int>) -> Int {
        guard range.count > 0 else { return range.lowerBound }
        return range.lowerBound + Int(next() % UInt64(range.count))
    }

    mutating func unit() -> CGFloat {
        CGFloat(Double(next() % 100_000) / 100_000.0)
    }

    mutating func spread(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        a + (b - a) * unit()
    }
}
