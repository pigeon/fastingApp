// FastingApp SwiftUI Starter (iOS + watchOS)
// Single-file drop-in to demonstrate the wireframes from fasting_app_wireframes.md
// Uses only standard SwiftUI + UserNotifications. HealthKit is stubbed.
// Xcode 15+ / iOS 17+ / watchOS 10+

import SwiftUI
import UserNotifications
import Combine

// MARK: - Models

enum FastingPlan: Equatable, Identifiable {
    case sixteenEight, eighteenSix, twentyFour, custom(hours: Int)

    var id: String { name }

    var fastingHours: Int {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .custom(let h): return max(1, h)
        }
    }

    var name: String {
        switch self {
        case .sixteenEight: return "16:8"
        case .eighteenSix: return "18:6"
        case .twentyFour: return "20:4"
        case .custom(let h): return "Custom (\(h):\(24 - min(24, h)))"
        }
    }

    static var presets: [FastingPlan] { [.sixteenEight, .eighteenSix, .twentyFour] }
}

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

// MARK: - Persistence

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
        guard let data = defaults.data(forKey: sessionsKey), let items = try? JSONDecoder().decode([FastSession].self, from: data) else { return [] }
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

// MARK: - Notifications

enum LocalNotify {
    static func requestAuth() async -> Bool {
        let center = UNUserNotificationCenter.current()
        // Async (non-throwing): current settings
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        // Throwing: ask for permission
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
        if let m = preEndMinutes { schedule(id: session.id.uuidString + ".preend", title: "Almost there", fire: session.scheduledEnd.addingTimeInterval(TimeInterval(-m * 60))) }

        // Snooze baseline (no immediate scheduling here; we schedule only on demand)
        if let sm = snoozeMinutes { _ = sm } // placeholder to avoid warning
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

// MARK: - ViewModel

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
            // Force UI updates each second for progress text/ring
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
            await LocalNotify.scheduleEndNotification(for: s, preEndMinutes: reminders.preEndMinutes, snoozeMinutes: reminders.snoozeMinutes)
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

    // Derived
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
        // For simplicity, show time until you tap Start. Could be replaced with a schedule.
        return "—"
    }

    static func hmsString(from interval: TimeInterval) -> String {
        let seconds = max(Int(interval), 0)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        return String(format: "%dh %02dm", h, m)
    }
}

// MARK: - Views

struct RootView: View {
    @EnvironmentObject var vm: FastingViewModel
    var body: some View {
        Group {
            if vm.onboarded { HomeShell() } else { OnboardingView() }
        }
    }
}

// MARK: Home + Tabs

struct HomeShell: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "largecircle.fill.circle") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var vm: FastingViewModel
    @State private var now = Date()

    var body: some View {
        VStack(spacing: 16) {
            Text(vm.status == .fasting ? "Status: FASTING" : "Status: EATING")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ProgressRing(progress: vm.progress(now: now))
                .frame(width: 160, height: 160)
                .padding(.vertical, 4)

            Group {
                if vm.status == .fasting, let s = vm.active {
                    Text("Remaining: \(FastingViewModel.hmsString(from: s.scheduledEnd.timeIntervalSince(now)))")
                    Text("Start: \(timeString(s.start))  |  End: \(timeString(s.scheduledEnd))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) { vm.endFast() } label: { Text("Stop Fast") }
                        .buttonStyle(.borderedProminent)
                    HStack {
                        Button("Snooze \(vm.reminders.snoozeMinutes)m") { Task { try await vm.snooze() } }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("Time until fasting: \(vm.remainingString())")
                    Button { Task { await vm.startFast() } } label: { Text("Start Fast") }
                        .buttonStyle(.borderedProminent)
                }
            }
            Spacer()
        }
        .padding()
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now = $0 }
        .navigationTitle("Fasting")
    }

    func timeString(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: d)
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject var vm: FastingViewModel
    @State private var selectedPreset: FastingPlan = .sixteenEight
    @State private var customHours: Int = 16
    @State private var remindersOn: Bool = true

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer(minLength: 8)
                Image(systemName: "timer.circle.fill").font(.system(size: 64))
                Text("Track your fasting easily").font(.title2).bold()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Select fasting plan:").font(.headline)
                    HStack { ForEach(FastingPlan.presets) { plan in
                        PlanChip(plan: plan, selected: selectedPreset == plan) { selectedPreset = plan }
                    } }
                    HStack {
                        Stepper("Custom hours: \(customHours)", value: $customHours, in: 1...23)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("Reminders", isOn: $remindersOn)
                Button("Allow Notifications") {
                    Task { _ = await LocalNotify.requestAuth() }
                }
                .buttonStyle(.bordered)

                Button("Finish Setup") {
                    vm.plan = selectedPreset == .custom(hours: 0) ? .custom(hours: customHours) : selectedPreset
                    vm.reminders.enabled = remindersOn
                    vm.onboarded = true
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Get Started")
        }
    }
}

struct PlanChip: View {
    let plan: FastingPlan
    let selected: Bool
    var action: () -> Void
    var body: some View {
        Button(plan.name) { action() }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(selected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.15))
            .clipShape(Capsule())
    }
}

// MARK: - History

struct HistoryView: View {
    @EnvironmentObject var vm: FastingViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(vm.sessions) { s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dateString(s.start))
                            .font(.headline)
                        Text("\(s.planHours):\(24 - s.planHours) | \(doneHours(s))h done")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: vm.deleteSessions)

                Section {
                    WeeklyChartPlaceholder()
                } header: { Text("Weekly Chart") }
            }
            .navigationTitle("History")
            .toolbar { EditButton() }
        }
    }

    func dateString(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }
    func doneHours(_ s: FastSession) -> Int {
        let end = s.completedAt ?? min(Date(), s.scheduledEnd)
        let hrs = Int(end.timeIntervalSince(s.start) / 3600)
        return max(0, min(hrs, s.planHours))
    }
}

struct WeeklyChartPlaceholder: View {
    var body: some View {
        HStack {
            Image(systemName: "chart.bar.xaxis")
            Text("Weekly chart coming soon")
            Spacer()
        }
        .foregroundStyle(.secondary)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @EnvironmentObject var vm: FastingViewModel
    @State private var customHours: Double = 16
    @State private var showHealthKitInfo = false

    var body: some View {
        Form {
            Section("Fasting Plan") {
                Picker("Plan", selection: Binding(
                    get: {
                        switch vm.plan {
                        case .sixteenEight: return 0
                        case .eighteenSix: return 1
                        case .twentyFour: return 2
                        case .custom: return 3
                        }
                    },
                    set: { idx in
                        switch idx {
                        case 0: vm.plan = .sixteenEight
                        case 1: vm.plan = .eighteenSix
                        case 2: vm.plan = .twentyFour
                        default: vm.plan = .custom(hours: Int(customHours))
                        }
                    }
                )) {
                    Text("16:8").tag(0); Text("18:6").tag(1); Text("20:4").tag(2); Text("Custom").tag(3)
                }
                if case .custom(let h) = vm.plan { Slider(value: Binding(get: { Double(h) }, set: { vm.plan = .custom(hours: Int($0)) }), in: 1...23, step: 1) { Text("Hours") } }
            }

            Section("Reminders") {
                Toggle("Enable", isOn: $vm.reminders.enabled)
                Toggle("Start-of-fast alert", isOn: $vm.reminders.startAlert)
                Toggle("End-of-fast alert", isOn: $vm.reminders.endAlert)
                Picker("Pre-end reminder", selection: Binding(get: { vm.reminders.preEndMinutes ?? 0 }, set: { vm.reminders.preEndMinutes = $0 == 0 ? nil : $0 })) {
                    Text("Off").tag(0)
                    Text("5m").tag(5)
                    Text("10m").tag(10)
                    Text("30m").tag(30)
                }
                Stepper("Snooze: \(vm.reminders.snoozeMinutes)m", value: $vm.reminders.snoozeMinutes, in: 5...60, step: 5)
            }

            Section("Integrations") {
                Toggle("Link HealthKit", isOn: $showHealthKitInfo)
                    .onChange(of: showHealthKitInfo) { _, _ in }
                if showHealthKitInfo {
                    Text("HealthKit integration placeholder. Add read/write for mindful minutes or nutrition as needed.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Display") {
                Toggle("24-hour time", isOn: $vm.timeFormat24h)
            }

            Section { NavigationLink("About / Privacy") { AboutView() } }
        }
        .navigationTitle("Settings")
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Text("Intermittent Fasting – Sample App")
            Text("This is an open-source starter to showcase wireframes.")
            Text("No data leaves your device.")
        }
        .navigationTitle("About & Privacy")
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    var progress: Double // 0...1

    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AngularGradient(gradient: Gradient(colors: [.blue, .green, .mint]), center: .center), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.smooth(duration: 0.3), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.title2).bold()
        }
    }
}

// MARK: - watchOS pieces (minimal stubs, keep in same file for illustration)
#if os(watchOS)
import WatchKit

final class NotificationController: WKUserNotificationHostingController<NotificationView> {
    override var body: NotificationView { NotificationView() }
}

struct NotificationView: View {
    var body: some View { Text("Fasting complete") }
}

struct WatchMainView: View {
    @EnvironmentObject var vm: FastingViewModel
    var body: some View {
        VStack(spacing: 12) {
            ProgressRing(progress: vm.progress())
                .frame(width: 90, height: 90)
            if vm.status == .fasting { Button("Stop Fast") { vm.endFast() } } else { Button("Start Fast") { Task { await vm.startFast() } } }
        }.padding()
    }
}
#endif

// MARK: - Previews

#Preview("Home (Fasting)") {
    let vm = FastingViewModel()
    let start = Date().addingTimeInterval(-60*60*10)
    vm.onboarded = true
    Task { await vm.startFast(now: start) }
    return HomeView().environmentObject(vm)
}

#Preview("Onboarding") { OnboardingView().environmentObject(FastingViewModel()) }
