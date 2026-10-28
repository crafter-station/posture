import AppKit
import UserNotifications

@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()

    func prepare() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func nudge(after seconds: Double, sound: Bool) {
        let content = UNMutableNotificationContent()
        content.title = "Sit up straight"
        content.body = "You've been slouching for \(Duration.text(seconds)). Shoulders back, chin level."
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "posture.nudge", content: content, trigger: nil))
        if sound { NSSound(named: "Funk")?.play() }
    }

    func recovered(sound: Bool) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["posture.nudge"])
        if sound { NSSound(named: "Tink")?.play() }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

enum Duration {
    static func text(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }
}
