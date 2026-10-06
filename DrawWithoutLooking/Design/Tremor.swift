
import SwiftUI
import Combine

final class Tremor: ObservableObject {
    static let shared = Tremor()

    @Published private(set) var beat: UInt64 = 0x2B1F

    private let period: TimeInterval = 0.14
    private var ticker: Timer?
    private var held = 0

    private init() {}

    var steady: Bool = false {
        didSet {
            guard steady != oldValue else { return }
            steady ? stop() : resume()
        }
    }

    func resume() {
        guard !steady, held == 0, ticker == nil else { return }
        let t = Timer(timeInterval: period, repeats: true) { [weak self] _ in
            self?.beat &+= 0x9E3779B9
        }

        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
    }

    func hold() {
        held += 1
        stop()
    }

    func release() {
        held = max(0, held - 1)
        if held == 0 { resume() }
    }
}

struct Shaky<Content: View>: View {
    @ObservedObject private var tremor = Tremor.shared
    private let build: (UInt64) -> Content

    init(@ViewBuilder _ build: @escaping (UInt64) -> Content) {
        self.build = build
    }

    var body: some View { build(tremor.beat) }
}

func jitter(_ seed: UInt64, _ i: Int) -> CGFloat {
    var x = seed &+ (UInt64(bitPattern: Int64(i)) &* 0x9E3779B97F4A7C15)
    x ^= x >> 30
    x = x &* 0xBF58476D1CE4E5B9
    x ^= x >> 27
    x = x &* 0x94D049BB133111EB
    x ^= x >> 31
    return CGFloat(Double(x % 2001) / 1000.0 - 1.0)
}
