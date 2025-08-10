import Foundation
import UserNotifications

enum LocalNotify {
    static func requestAuth() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func scheduleEndNotification(for session: FastSession, preEndMinutes: Int?, snoozeMinutes: Int?) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let now = Date()

        func schedule(id: String, title: String, fire: Date) {
            guard fire > now else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = "Your \(session.planHours):\(24 - session.planHours) fast finishes at \(timeString(fire))."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fire.timeIntervalSinceNow, repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }

        // End notification
        schedule(id: session.id.uuidString + ".end", title: "Fasting complete", fire: session.scheduledEnd)

        // Pre-end reminder
        if let m = preEndMinutes {
            schedule(id: session.id.uuidString + ".preend", title: "Almost there", fire: session.scheduledEnd.addingTimeInterval(TimeInterval(-m * 60)))
        }

        // Snooze baseline
        if let sm = snoozeMinutes { _ = sm }
    }

    static func scheduleSnooze(minutes: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Reminder"
        content.body = "Check in with your fast."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        try await center.add(UNNotificationRequest(identifier: UUID().uuidString + ".snooze", content: content, trigger: trigger))
    }

    static func timeString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.timeStyle = .short
        fmt.dateStyle = .none
        return fmt.string(from: date)
    }
}
