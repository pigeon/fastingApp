import Foundation

final class Persistence {
    static let shared = Persistence()
    private let sessionsKey = "FastSessions.v1"
    private let planKey = "FastingPlan.v1"
    private let remindersKey = "ReminderSettings.v1"
    private let timeFormatKey = "TimeFormat24h.v1"
    private let onboardedKey = "Onboarded.v1"

    private let defaults = UserDefaults.standard

    func saveSessions(_ items: [FastSession]) { defaults.set(try? JSONEncoder().encode(items), forKey: sessionsKey) }
    func loadSessions() -> [FastSession] {
        guard let data = defaults.data(forKey: sessionsKey),
              let items = try? JSONDecoder().decode([FastSession].self, from: data) else { return [] }
        return items.sorted { $0.start > $1.start }
    }

    func savePlan(_ plan: FastingPlan) {
        switch plan {
        case .sixteenEight: defaults.set("16:8", forKey: planKey)
        case .eighteenSix: defaults.set("18:6", forKey: planKey)
        case .twentyFour: defaults.set("20:4", forKey: planKey)
        case .custom(let h): defaults.set("custom:\(h)", forKey: planKey)
        }
    }
    func loadPlan() -> FastingPlan {
        guard let s = defaults.string(forKey: planKey) else { return .sixteenEight }
        if s == "16:8" { return .sixteenEight }
        if s == "18:6" { return .eighteenSix }
        if s == "20:4" { return .twentyFour }
        if s.hasPrefix("custom:"), let h = Int(s.split(separator: ":").last ?? "16") { return .custom(hours: h) }
        return .sixteenEight
    }

    func saveReminders(_ r: ReminderSettings) { defaults.set(try? JSONEncoder().encode(r), forKey: remindersKey) }
    func loadReminders() -> ReminderSettings { (try? JSONDecoder().decode(ReminderSettings.self, from: defaults.data(forKey: remindersKey) ?? Data())) ?? ReminderSettings() }

    func setTimeFormat24h(_ on: Bool) { defaults.set(on, forKey: timeFormatKey) }
    func timeFormat24h() -> Bool { defaults.bool(forKey: timeFormatKey) }

    func setOnboarded(_ done: Bool) { defaults.set(done, forKey: onboardedKey) }
    func onboarded() -> Bool { defaults.bool(forKey: onboardedKey) }
}
