import Foundation
import Combine
import SwiftUI

@MainActor
final class FastingViewModel: ObservableObject {
    @Published var plan: FastingPlan { didSet { Persistence.shared.savePlan(plan) } }
    @Published var reminders: ReminderSettings { didSet { Persistence.shared.saveReminders(reminders) } }
    @Published private(set) var sessions: [FastSession]
    @Published private(set) var active: FastSession?
    @Published var timeFormat24h: Bool { didSet { Persistence.shared.setTimeFormat24h(timeFormat24h) } }
    @Published var onboarded: Bool { didSet { Persistence.shared.setOnboarded(onboarded) } }

    private var timer: AnyCancellable?

    init() {
        self.plan = Persistence.shared.loadPlan()
        self.reminders = Persistence.shared.loadReminders()
        self.sessions = Persistence.shared.loadSessions()
        self.timeFormat24h = Persistence.shared.timeFormat24h()
        self.onboarded = Persistence.shared.onboarded()
        self.active = sessions.first(where: { $0.completedAt == nil && Date() < $0.scheduledEnd })
        tickTimer()
    }

    func tickTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { [weak self] _ in
            guard let self else { return }
            self.objectWillChange.send()
        }
    }

    func startFast(now: Date = Date()) async {
        let s = FastSession.new(planHours: plan.fastingHours, start: now)
        active = s
        sessions.insert(s, at: 0)
        Persistence.shared.saveSessions(sessions)
        if reminders.enabled && reminders.endAlert {
            _ = await LocalNotify.requestAuth()
            await LocalNotify.scheduleEndNotification(for: s, preEndMinutes: reminders.preEndMinutes, snoozeMinutes: reminders.snoozeMinutes, is24h: timeFormat24h)
        }
    }

    func endFast(at date: Date = Date()) {
        guard var s = active else { return }
        s.completedAt = date
        if let idx = sessions.firstIndex(where: { $0.id == s.id }) { sessions[idx] = s }
        active = nil
        Persistence.shared.saveSessions(sessions)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func snooze() async throws {
        guard reminders.enabled else { return }
        try await LocalNotify.scheduleSnooze(minutes: reminders.snoozeMinutes)
    }

    func deleteSessions(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        Persistence.shared.saveSessions(sessions)
    }

    var status: FastStatus { active == nil ? .eating : .fasting }

    func progress(now: Date = Date()) -> Double {
        guard let s = active else { return 0 }
        let total = s.scheduledEnd.timeIntervalSince(s.start)
        let done = now.timeIntervalSince(s.start)
        return min(max(done / total, 0), 1)
    }

    func remainingString(now: Date = Date()) -> String {
        switch status {
        case .fasting:
            guard let s = active else { return "" }
            let remaining = s.scheduledEnd.timeIntervalSince(now)
            return Self.hmsString(from: remaining)
        case .eating:
            return timeUntilNextFastString()
        }
    }

    private func timeUntilNextFastString() -> String {
        return "—"
    }

    static func hmsString(from interval: TimeInterval) -> String {
        let seconds = max(Int(interval), 0)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%dh %02dm", h, m)
    }
}
