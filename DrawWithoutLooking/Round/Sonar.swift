
import Combine
import AVFoundation

private struct Tone {
    var freq: Double = 300
    var gain: Double = 0
    var target: Double = 0
    var phase: Double = 0
}

final class Sonar: ObservableObject {
    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?
    private var rate: Double = 44100
    private(set) var live = false

    private let tone = UnsafeMutablePointer<Tone>.allocate(capacity: 1)

    private let low = 165.0
    private let high = 880.0

    init() {
        tone.initialize(to: Tone())
    }

    deinit {
        engine.stop()
        tone.deinitialize(count: 1)
        tone.deallocate()
    }

    func open() {
        guard source == nil else {
            resumeEngine()
            return
        }
        do {

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            live = false
            return
        }

        let outFormat = engine.outputNode.inputFormat(forBus: 0)
        rate = outFormat.sampleRate > 0 ? outFormat.sampleRate : 44100
        guard let mono = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1) else {
            live = false
            return
        }

        let box = tone
        let sr = rate
        let node = AVAudioSourceNode { _, _, frames, buffers in
            let abl = UnsafeMutableAudioBufferListPointer(buffers)
            for i in 0..<Int(frames) {

                box.pointee.gain += (box.pointee.target - box.pointee.gain) * 0.0016
                box.pointee.phase += 2 * .pi * box.pointee.freq / sr
                if box.pointee.phase > 2 * .pi { box.pointee.phase -= 2 * .pi }
                let v = Float(sin(box.pointee.phase) * box.pointee.gain)
                for buf in abl {
                    guard let ptr = buf.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    ptr[i] = v
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: mono)
        source = node
        resumeEngine()
    }

    private func resumeEngine() {
        do {
            try engine.start()
            live = true
        } catch {

            live = false
        }
    }

    func close() {
        tone.pointee.target = 0
        engine.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    func touch(x: CGFloat, y: CGFloat) {
        guard live else { return }
        tone.pointee.freq = low * pow(high / low, Double(1 - max(0, min(1, y))))
        tone.pointee.target = 0.16
        source?.pan = Float(max(-1, min(1, (x - 0.5) * 2)))
    }

    func hush() {
        tone.pointee.target = 0
    }
}
