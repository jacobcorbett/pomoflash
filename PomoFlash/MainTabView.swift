// MainTabView.swift
import SwiftUI

struct MainTabView: View {
    @State private var selection = 1 // start on the middle tab (Timer)

    var body: some View {
        TabView(selection: $selection) {
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
                .tag(0)

            ContentView() // your existing timer view
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
    }
}

// MARK: - Left Tab: Stats

struct StatsView: View {
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60

    private var totalFocusSeconds: Int {
        sessionsCompleted * workDuration
    }

    private var totalFocusReadable: String {
        let h = totalFocusSeconds / 3600
        let m = (totalFocusSeconds % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
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
                    Button(role: .destructive) {
                        sessionsCompleted = 0
                    } label: {
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

// MARK: - Right Tab: Profile

struct ProfileView: View {
    @AppStorage("displayName") private var displayName = "You"
    // mirror the timer’s persisted keys so “Reset everything” can clear them from here too:
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
                // Profile Header
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

                // Account-ish settings
                Section("Account") {
                    Toggle(isOn: .constant(true)) {
                        Label("Keep screen awake on Timer", systemImage: "lock.open.display")
                    }
                    .disabled(true) // placeholder for now

                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }

                // Danger Zone
                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
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
        let parts = name.split(separator: " ").map { String($0.prefix(1)) }
        return parts.prefix(2).joined().uppercased().ifEmpty("Y")
    }

    private func resetEverything() {
        isRunning = false
        timerType = "Work"
        timeRemaining = Double(workDuration)
        sessionsCompleted = 0
        lastActiveTime = 0
        // labels & durations stay as user-preferences; remove next two lines if you want those reset too:
        // workLabel = "Work"
        // breakLabel = "Break"
    }
}

// MARK: - Simple About screen

struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("App", value: "PomoFlash")
                LabeledContent("Version", value: "1.0")
                LabeledContent("Made with", value: "SwiftUI")
            }
        }
        .navigationTitle("About")
    }
}

// Small util to default empty strings
fileprivate extension String {
    func ifEmpty(_ fallback: String) -> String { self.isEmpty ? fallback : self }
}

#Preview {
    MainTabView()
}
