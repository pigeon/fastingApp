import SwiftUI

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
