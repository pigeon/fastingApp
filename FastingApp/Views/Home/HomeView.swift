import SwiftUI

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
                    Text("Start: \(Date.shortTimeString(s.start, is24h: vm.timeFormat24h))  |  End: \(Date.shortTimeString(s.scheduledEnd, is24h: vm.timeFormat24h))")
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

}

#Preview("Home (Fasting)") {
    let vm = FastingViewModel()
    let start = Date().addingTimeInterval(-60*60*10)
    vm.onboarded = true
    Task { await vm.startFast(now: start) }
    return HomeView().environmentObject(vm)
}
