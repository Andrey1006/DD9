
import UIKit

enum Bumper {
    static var on = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)
    private static let notice = UINotificationFeedbackGenerator()

    private static var lastEdge = Date.distantPast

    static func warm() {
        guard on else { return }
        light.prepare(); rigid.prepare(); soft.prepare()
    }

    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard on else { return }
        switch style {
        case .rigid: rigid.impactOccurred()
        case .soft: soft.impactOccurred(intensity: 0.7)
        default: light.impactOccurred(intensity: 0.55)
        }
    }

    static func edge() {
        guard on, Date().timeIntervalSince(lastEdge) > 0.14 else { return }
        lastEdge = Date()
        rigid.impactOccurred(intensity: 0.85)
        rigid.prepare()
    }

    static func lift() {
        guard on else { return }
        soft.impactOccurred(intensity: 0.5)
        soft.prepare()
    }

    static func verdict(_ good: Bool) {
        guard on else { return }
        notice.notificationOccurred(good ? .success : .warning)
    }
}
