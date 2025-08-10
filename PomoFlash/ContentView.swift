import SwiftUI
import AVFoundation

struct ContentView: View {
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60

    @State private var timeRemaining: Double = 25.0 * 60.0
    @State private var isRunning = false
    @State private var timerType = "Work" // "Work" or "Break"
    @State private var timer: Timer?
    @State private var sessionsCompleted = 0
    @State private var showingSettings = false
    @State private var audioPlayer: AVAudioPlayer?

    private let tickInterval = 1.0 / 60.0 // ~60 FPS

    var progress: Double {
        let total = timerType == "Work" ? Double(workDuration) : Double(breakDuration)
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - (timeRemaining / total)))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text(timerType)
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
                    onSave: { resetEverything() },
                    onResetAll: { resetEverything() }
                )
            }
        }
        .onAppear {
            timeRemaining = Double(workDuration)
        }
    }

    // MARK: - Timer Control

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        timer?.invalidate()

        if timeRemaining <= 0 {
            finishPhase()
            return
        }

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
    }

    func resetTimer() {
        pauseTimer()
        timeRemaining = timerType == "Work" ? Double(workDuration) : Double(breakDuration)
    }

    func resetEverything() {
        pauseTimer()
        timerType = "Work"
        timeRemaining = Double(workDuration)
        sessionsCompleted = 0
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
    }

    // MARK: - Utils

    func formatTime(_ seconds: Double) -> String {
        let s = max(0, Int(ceil(seconds)))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    func playSound() {
        guard let soundURL = Bundle.main.url(forResource: "ding", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }
}

struct SettingsView: View {
    @Binding var workDuration: Int
    @Binding var breakDuration: Int
    var onSave: () -> Void
    var onResetAll: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var showResetAlert = false
    @State private var showWorkPicker = false
    @State private var showBreakPicker = false

    var body: some View {
        NavigationView {
            Form {
                // WORK
                Section("Work Duration") {
                    // Quick presets stay visible
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

                // BREAK
                Section("Break Duration") {
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

                // DEV TOOLS
                Section("Dev Tools") {
                    Button("Reset Everything", role: .destructive) {
                        showResetAlert = true
                    }
                    .alert("Reset Everything?", isPresented: $showResetAlert) {
                        Button("Cancel", role: .cancel) {}
                        Button("Reset", role: .destructive) { onResetAll() }
                    } message: {
                        Text("This will reset the timer, switch back to Work, and clear today’s session count.")
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
