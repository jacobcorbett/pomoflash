// DevToolsView.swift
import SwiftUI
import UserNotifications

struct DevToolsView: View {
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60
    @AppStorage("workLabel") private var workLabel = "Work"
    @AppStorage("breakLabel") private var breakLabel = "Break"
    @AppStorage("timeRemaining") private var timeRemaining: Double = 25.0 * 60.0
    @AppStorage("isRunning") private var isRunning = false
    @AppStorage("timerType") private var timerType = "Work"
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("lastActiveTime") private var lastActiveTime: Double = 0

    @State private var pendingCount = 0
    @State private var showResetAlert = false

    var body: some View {
        List {
            // --- Runtime snapshot ---
            Section("Runtime State") {
                LabeledContent("Timer type", value: timerType)
                LabeledContent("Is running", value: isRunning ? "true" : "false")
                LabeledContent("Time remaining", value: formatTime(timeRemaining))
                LabeledContent("Sessions completed", value: "\(sessionsCompleted)")
                LabeledContent("Last active", value: formatDate(lastActiveTime))
                LabeledContent("Pending notifications", value: "\(pendingCount)")
                LabeledContent("Work label", value: workLabel)
                LabeledContent("Break label", value: breakLabel)

                Button("Refresh Pending Notifications") { refreshPending() }
            }

            // --- Quick actions ---
            Section("Actions") {
                Button("Complete current phase") { completeCurrentPhase() }
                Button("Send test notification now") { sendTestNotificationNow() }
                Button("Schedule 5-sec test notification") { scheduleTestNotification(after: 5) }
                Button("Cancel pending notifications") { cancelBackgroundNotifications() }
            }

            // --- Edit state ---
            Section("Edit State") {
                Stepper("Sessions: \(sessionsCompleted)",
                        onIncrement: { sessionsCompleted += 1 },
                        onDecrement: { sessionsCompleted = max(0, sessionsCompleted - 1) })

                Button("Reset everything", role: .destructive) { showResetAlert = true }
                    .alert("Reset Everything?", isPresented: $showResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) { resetEverything() }
                    }
            }

            // --- Labels (your request) ---
            Section("Labels") {
                HStack {
                    Text("Work label")
                    Spacer()
                    TextField("Work", text: $workLabel)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                HStack {
                    Text("Break label")
                    Spacer()
                    TextField("Break", text: $breakLabel)
                        .multilineTextAlignment(.trailing)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                }
                Button("Reset labels to defaults") {
                    workLabel = "Work"
                    breakLabel = "Break"
                }
            }

            // --- Durations snapshot ---
            Section("Durations") {
                LabeledContent("Work length", value: mmss(workDuration))
                LabeledContent("Break length", value: mmss(breakDuration))
            }
        }
        .navigationTitle("Dev Tools")
        .onAppear { refreshPending() }
    }

    // MARK: - Actions

    private func completeCurrentPhase() {
        if timerType == "Work" {
            timerType = "Break"
            timeRemaining = Double(breakDuration)
            sessionsCompleted += 1
        } else {
            timerType = "Work"
            timeRemaining = Double(workDuration)
        }
    }

    private func sendTestNotificationNow() {
        let content = UNMutableNotificationContent()
        content.title = "PomoFlash (Test)"
        content.body = "Immediate test notification."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        refreshPending()
    }

    private func scheduleTestNotification(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "PomoFlash (Test)"
        content.body = "Scheduled test notification in \(Int(seconds)) seconds."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
        refreshPending()
    }

    private func cancelBackgroundNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        refreshPending()
    }

    private func resetEverything() {
        isRunning = false
        timerType = "Work"
        timeRemaining = Double(workDuration)
        sessionsCompleted = 0
        lastActiveTime = 0
        cancelBackgroundNotifications()
    }

    private func refreshPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { reqs in
            DispatchQueue.main.async { pendingCount = reqs.count }
        }
    }

    // MARK: - Formatters

    private func formatTime(_ seconds: Double) -> String {
        let s = max(0, Int(ceil(seconds)))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private func formatDate(_ epoch: Double) -> String {
        guard epoch > 0 else { return "—" }
        let date = Date(timeIntervalSince1970: epoch)
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func mmss(_ seconds: Int) -> String {
        String(format: "%02d:%02d", max(0, seconds)/60, max(0, seconds)%60)
    }
}
