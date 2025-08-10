import SwiftUI

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

#Preview("Onboarding") { OnboardingView().environmentObject(FastingViewModel()) }
