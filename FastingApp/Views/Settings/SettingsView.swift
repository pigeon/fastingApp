import SwiftUI

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
