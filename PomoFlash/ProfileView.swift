import SwiftUI

struct ProfileView: View {
    @AppStorage("displayName") private var displayName = "You"

    // Mirror timer keys so “Reset timer data” works here too
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60
    @AppStorage("workLabel") private var workLabel = "Work"
    @AppStorage("breakLabel") private var breakLabel = "Break"
    @AppStorage("timeRemaining") private var timeRemaining: Double = 25.0 * 60.0
    @AppStorage("isRunning") private var isRunning = false
    @AppStorage("timerType") private var timerType = "Work"
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("lastActiveTime") private var lastActiveTime: Double = 0

    @State private var showResetAlert = false

    var body: some View {
        NavigationView {
            List {
                // Header
                Section {
                    HStack(spacing: 16) {
                        avatar
                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayName.isEmpty ? "You" : displayName)
                                .font(.title2.bold())
                            Text("Pomodoro Enthusiast")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)

                    HStack {
                        Text("Display name")
                        Spacer()
                        TextField("Your name", text: $displayName)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.words)
                    }
                }

                Section("Account") {
                    Toggle(isOn: .constant(true)) {
                        Label("Keep screen awake on Timer", systemImage: "lock.open.display")
                    }
                    .disabled(true) // placeholder

                    NavigationLink { AboutView() } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }

                Section("Danger Zone") {
                    Button(role: .destructive) { showResetAlert = true } label: {
                        Label("Reset timer data", systemImage: "arrow.counterclockwise")
                    }
                    .alert("Reset Everything?", isPresented: $showResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) { resetEverything() }
                    } message: {
                        Text("Resets the timer, session counts, and returns to Work.")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 64, height: 64)
            Text(initials(from: displayName))
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Profile picture")
    }

    private func initials(from name: String) -> String {
        let parts = name.split(whereSeparator: { $0.isWhitespace })
        let letters = parts.prefix(2).map { String($0.prefix(1)).uppercased() }
        return letters.joined().ifEmpty("Y")
    }

    private func resetEverything() {
        isRunning = false
        timerType = "Work"
        timeRemaining = Double(workDuration)
        sessionsCompleted = 0
        lastActiveTime = 0
        // To also reset labels to defaults, uncomment:
        // workLabel = "Work"
        // breakLabel = "Break"
    }
}
