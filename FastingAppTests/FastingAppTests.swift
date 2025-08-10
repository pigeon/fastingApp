import XCTest
@testable import FastingApp

final class FastingAppTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
    }

    @MainActor
    func testStartAndEndFast() async {
        let vm = FastingViewModel()
        vm.reminders.enabled = false
        vm.plan = .custom(hours: 8)
        let start = Date()
        XCTAssertNil(vm.active)
        await vm.startFast(now: start)
        XCTAssertNotNil(vm.active)
        XCTAssertEqual(vm.sessions.count, 1)
        XCTAssertEqual(vm.active?.start, start)
        XCTAssertEqual(vm.sessions.first?.planHours, vm.plan.fastingHours)
        let end = start.addingTimeInterval(3600)
        vm.endFast(at: end)
        XCTAssertNil(vm.active)
        XCTAssertEqual(vm.sessions.first?.completedAt, end)
    }

    func testPersistenceEncodingDecoding() {
        let p = Persistence.shared
        let start = Date()
        let sessions = [
            FastSession(id: UUID(), planHours: 16, start: start, end: nil, completedAt: nil),
            FastSession(id: UUID(), planHours: 18, start: start.addingTimeInterval(-3600), end: nil, completedAt: start.addingTimeInterval(-1800))
        ]
        p.saveSessions(sessions)
        let loadedSessions = p.loadSessions()
        XCTAssertEqual(loadedSessions, sessions.sorted { $0.start > $1.start })
        p.savePlan(.custom(hours: 10))
        XCTAssertEqual(p.loadPlan(), .custom(hours: 10))
        let reminders = ReminderSettings(enabled: true, startAlert: false, endAlert: false, preEndMinutes: nil, snoozeMinutes: 5)
        p.saveReminders(reminders)
        XCTAssertEqual(p.loadReminders(), reminders)
    }

    @MainActor
    func testProgressAndHmsString() async {
        let vm = FastingViewModel()
        vm.reminders.enabled = false
        vm.plan = .custom(hours: 10)
        let start = Date()
        await vm.startFast(now: start)
        XCTAssertEqual(vm.progress(now: start), 0, accuracy: 0.001)
        let mid = start.addingTimeInterval(5 * 3600)
        XCTAssertEqual(vm.progress(now: mid), 0.5, accuracy: 0.001)
        let after = start.addingTimeInterval(15 * 3600)
        XCTAssertEqual(vm.progress(now: after), 1, accuracy: 0.001)
        XCTAssertEqual(FastingViewModel.hmsString(from: 3661), "1h 01m")
        XCTAssertEqual(FastingViewModel.hmsString(from: -10), "0h 00m")
    }
}
