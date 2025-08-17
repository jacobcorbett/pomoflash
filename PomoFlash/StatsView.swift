import SwiftUI

struct StatsView: View {
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60

    private var totalFocusSeconds: Int { sessionsCompleted * workDuration }
    private var totalFocusReadable: String {
        let h = totalFocusSeconds / 3600
        let m = (totalFocusSeconds % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }

    var body: some View {
        NavigationView {
            List {
                Section("Today / Overall (simple)") {
                    HStack {
                        Text("Sessions completed")
                        Spacer()
                        Text("\(sessionsCompleted)")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Estimated focus time")
                        Spacer()
                        Text(totalFocusReadable)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Quick Actions") {
                    Button(role: .destructive) { sessionsCompleted = 0 } label: {
                        Label("Clear session count", systemImage: "trash")
                    }
                }

                Section("Info") {
                    LabeledContent("Work length", value: format(mmss: workDuration))
                    LabeledContent("Break length", value: format(mmss: breakDuration))
                }
            }
            .navigationTitle("Stats")
        }
    }

    private func format(mmss seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
