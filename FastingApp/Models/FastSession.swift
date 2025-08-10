import Foundation

struct ReminderSettings: Codable, Equatable {
    var enabled: Bool = true
    var startAlert: Bool = true
    var endAlert: Bool = true
    var preEndMinutes: Int? = 10 // nil disables
    var snoozeMinutes: Int = 10
}

enum FastStatus: String, Codable { case fasting, eating }

struct FastSession: Identifiable, Codable, Equatable {
    let id: UUID
    var planHours: Int
    var start: Date
    var end: Date? // scheduled end (target), finalized when ended
    var completedAt: Date? // actual end time when user taps End

    var isActive: Bool { completedAt == nil && Date() < scheduledEnd }
    var scheduledEnd: Date { start.addingTimeInterval(TimeInterval(planHours) * 3600) }
    var displayEnd: Date { end ?? scheduledEnd }

    static func new(planHours: Int, start: Date = Date()) -> FastSession {
        .init(id: UUID(), planHours: planHours, start: start, end: nil, completedAt: nil)
    }
}
