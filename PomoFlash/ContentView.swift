// ContentView.swift
import SwiftUI
import AVFoundation
import UserNotifications
import AudioToolbox

struct ContentView: View {
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60
    @AppStorage("workLabel") private var workLabel = "Work"
    @AppStorage("breakLabel") private var breakLabel = "Break"
    
    // Persistent state using @AppStorage
    @AppStorage("timeRemaining") private var timeRemaining: Double = 25.0 * 60.0
    @AppStorage("isRunning") private var isRunning = false
    @AppStorage("timerType") private var timerType = "Work"
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 0
    @AppStorage("lastActiveTime") private var lastActiveTime: Double = 0
    
    @State private var timer: Timer?
    @State private var showingSettings = false
    @State private var audioPlayer: AVAudioPlayer?
    
    private let tickInterval = 1.0 / 60.0

    var progress: Double {
        let total = timerType == "Work" ? Double(workDuration) : Double(breakDuration)
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - (timeRemaining / total)))
    }
    
    private var currentLabel: String {
        timerType == "Work" ? workLabel : breakLabel
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text(currentLabel)
                    .font(.title)
                    .foregroundColor(timerType == "Work" ? .red : .green)

                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.2)
                        .foregroundColor(timerType == "Work" ? .red : .green)

                    Circle()
                        .trim(from: 0.0, to: progress)
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .foregroundColor(timerType == "Work" ? .red : .green)
                        .rotationEffect(.degrees(-90))

                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                }
                .frame(width: 200, height: 200)

                HStack(spacing: 20) {
                    Button(isRunning ? "Pause" : "Start") {
                        isRunning ? pauseTimer() : startTimer()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset Timer") {
                        resetTimer()
                    }
                    .buttonStyle(.bordered)
                }

                Text("Sessions Completed: \(sessionsCompleted)")
                    .font(.headline)
            }
            .padding()
            .navigationTitle("Pomodoro")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    workDuration: $workDuration,
                    breakDuration: $breakDuration,
                    workLabel: $workLabel,
                    breakLabel: $breakLabel,
                    onSave: { resetEverything() },
                    onResetAll: { resetEverything() }
                )
            }
            .onAppear {
                syncTimerFromBackground()
                if timeRemaining <= 0 {
                    timeRemaining = Double(workDuration)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                saveCurrentState()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                syncTimerFromBackground()
            }
        }
    }

    // MARK: - Background Persistence
    
    private func saveCurrentState() {
        lastActiveTime = Date().timeIntervalSince1970
        // AppStorage properties automatically save
    }
    
    private func syncTimerFromBackground() {
        guard lastActiveTime > 0 else { return }
        
        let currentTime = Date().timeIntervalSince1970
        let timeElapsed = currentTime - lastActiveTime
        
        if isRunning && timeElapsed > 0 {
            // Calculate how much time should have passed
            timeRemaining = max(0, timeRemaining - timeElapsed)
            
            // Handle phase transitions that happened in background
            while timeRemaining <= 0 && isRunning {
                finishPhaseInBackground()
            }
            
            // If still running after background phase transitions, restart visual timer
            if isRunning && timeRemaining > 0 {
                startVisualTimer()
                scheduleBackgroundNotification() // Reschedule for the current phase
            }
        }
    }
    
    private func finishPhaseInBackground() {
        if timerType == "Work" {
            timerType = "Break"
            timeRemaining += Double(breakDuration)
            sessionsCompleted += 1
        } else {
            timerType = "Work"
            timeRemaining += Double(workDuration)
        }
        
        // Don't schedule additional notifications here - they're already scheduled
        // when the timer starts, and we don't want duplicate sounds
    }

    // MARK: - Timer Control

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        lastActiveTime = Date().timeIntervalSince1970
        
        if timeRemaining <= 0 {
            finishPhase()
            return
        }
        
        startVisualTimer()
        scheduleBackgroundNotification()
    }
    
    private func startVisualTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= tickInterval
                if timeRemaining <= 0 {
                    finishPhase()
                }
            } else {
                finishPhase()
            }
        }
        if let t = timer {
            RunLoop.current.add(t, forMode: .common)
        }
    }

    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        cancelBackgroundNotifications()
        saveCurrentState()
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = timerType == "Work" ? Double(workDuration) : Double(breakDuration)
        cancelBackgroundNotifications()
    }

    func resetEverything() {
        pauseTimer()
        timerType = "Work"
        timeRemaining = Double(workDuration)
        sessionsCompleted = 0
        lastActiveTime = 0
        cancelBackgroundNotifications()
    }

    private func finishPhase() {
        pauseTimer()
        playSound()
        if timerType == "Work" {
            timerType = "Break"
            timeRemaining = Double(breakDuration)
            sessionsCompleted += 1
        } else {
            timerType = "Work"
            timeRemaining = Double(workDuration)
        }
        
        // Auto-start the next phase
        startTimer()
    }
    
    // MARK: - Background Notifications
    
    private func scheduleBackgroundNotification() {
        let center = UNUserNotificationCenter.current()
        
        // Cancel any existing notifications
        cancelBackgroundNotifications()
        
        // Only schedule if there's time remaining
        guard timeRemaining > 0 else { return }
        
        // Schedule notification for when current phase ends
        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Timer"
        content.body = timerType == "Work"
            ? "\(workLabel) session complete! Time for \(breakLabel.lowercased())."
            : "\(breakLabel) over! Ready for \(workLabel.lowercased())?"
        content.sound = .default
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pomodoroPhaseComplete",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    
    private func cancelBackgroundNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["pomodoroPhaseComplete"])
    }

    // MARK: - Utils

    func formatTime(_ seconds: Double) -> String {
        let s = max(0, Int(ceil(seconds)))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    func playSound() {
        // When app is active, just use haptic feedback (no sound)
        if UIApplication.shared.applicationState == .active {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            // When app is not active, use notification sound
            let center = UNUserNotificationCenter.current()
            center.getNotificationSettings { settings in
                if settings.authorizationStatus == .authorized {
                    let content = UNMutableNotificationContent()
                    content.title = "Pomodoro"
                    content.body = (self.timerType == "Work")
                        ? "\(self.workLabel) session done — time for \(self.breakLabel.lowercased())."
                        : "\(self.breakLabel) over — back to \(self.workLabel.lowercased())."
                    content.sound = .default

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
                    let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
                    center.add(req, withCompletionHandler: nil)
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }
}

// MARK: - Settings View (unchanged)

struct SettingsView: View {
    @Binding var workDuration: Int
    @Binding var breakDuration: Int
    @Binding var workLabel: String
    @Binding var breakLabel: String
    var onSave: () -> Void
    var onResetAll: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
    @State private var showWorkPicker = false
    @State private var showBreakPicker = false

    var body: some View {
        NavigationView {
            Form {
                // WORK SETTINGS
                Section("Work Session") {
                    // Label customization
                    HStack {
                        Text("Label:")
                        TextField("Work", text: $workLabel)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Duration presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            PresetChip(label: "15:00", seconds: 15*60, target: $workDuration)
                            PresetChip(label: "25:00", seconds: 25*60, target: $workDuration)
                            PresetChip(label: "50:00", seconds: 50*60, target: $workDuration)
                        }
                        .padding(.vertical, 4)
                    }

                    Text("Current: \(formatDuration(workDuration))")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    DisclosureGroup(isExpanded: $showWorkPicker) {
                        DurationPicker(totalSeconds: $workDuration, minutesRange: 0...120, secondsRange: 0...59)
                            .frame(height: 170)
                            .padding(.top, 6)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Custom (tap to adjust)")
                            Spacer()
                            Text(formatDuration(workDuration))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .animation(.easeInOut, value: showWorkPicker)
                }

                // BREAK SETTINGS
                Section("Break Session") {
                    // Label customization
                    HStack {
                        Text("Label:")
                        TextField("Break", text: $breakLabel)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Duration presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            PresetChip(label: "03:00", seconds: 3*60, target: $breakDuration)
                            PresetChip(label: "05:00", seconds: 5*60, target: $breakDuration)
                            PresetChip(label: "10:00", seconds: 10*60, target: $breakDuration)
                        }
                        .padding(.vertical, 4)
                    }

                    Text("Current: \(formatDuration(breakDuration))")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    DisclosureGroup(isExpanded: $showBreakPicker) {
                        DurationPicker(totalSeconds: $breakDuration, minutesRange: 0...60, secondsRange: 0...59)
                            .frame(height: 170)
                            .padding(.top, 6)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Custom (tap to adjust)")
                            Spacer()
                            Text(formatDuration(breakDuration))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                    .animation(.easeInOut, value: showBreakPicker)
                }

                Section("Dev Tools") {
                    Button("Reset Everything", role: .destructive) {
                        showResetAlert = true
                    }
                    .alert("Reset Everything?", isPresented: $showResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) { onResetAll() }
                    } message: {
                        Text("This will reset the timer, switch back to Work, and clear today's session count.")
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(); dismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct DurationPicker: View {
    @Binding var totalSeconds: Int
    var minutesRange: ClosedRange<Int> = 0...120
    var secondsRange: ClosedRange<Int> = 0...59

    var body: some View {
        HStack(spacing: 16) {
            Picker("Minutes", selection: Binding(
                get: { totalSeconds / 60 },
                set: { totalSeconds = $0 * 60 + totalSeconds % 60 }
            )) {
                ForEach(minutesRange, id: \.self) { m in
                    Text("\(m) min").tag(m)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)

            Picker("Seconds", selection: Binding(
                get: { totalSeconds % 60 },
                set: { totalSeconds = (totalSeconds / 60) * 60 + $0 }
            )) {
                ForEach(secondsRange, id: \.self) { s in
                    Text(String(format: "%02d sec", s)).tag(s)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}

struct PresetChip: View {
    let label: String
    let seconds: Int
    @Binding var target: Int

    var body: some View {
        Button(label) { target = seconds }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .clipShape(Capsule())
    }
}

#Preview {
    ContentView()
}
