import SwiftUI
import AVFoundation
import UserNotifications
import AudioToolbox

struct TimerView: View {
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

    private let tickInterval = 1.0 / 60.0

    var progress: Double {
        let total = timerType == "Work" ? Double(workDuration) : Double(breakDuration)
        guard total > 0 else { return 1 }
        return min(1, max(0, 1 - (timeRemaining / total)))
    }

    private var currentLabel: String { timerType == "Work" ? workLabel : breakLabel }

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
                        .animation(.easeInOut(duration: 0.15), value: progress)

                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                }
                .frame(width: 220, height: 220)

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
            }
            .padding()
            .navigationTitle("Pomodoro")
            .onAppear {
                syncTimerFromBackground()
                if timeRemaining <= 0 { timeRemaining = Double(workDuration) }
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
    }

    private func syncTimerFromBackground() {
        guard lastActiveTime > 0 else { return }
        let currentTime = Date().timeIntervalSince1970
        let timeElapsed = currentTime - lastActiveTime

        if isRunning && timeElapsed > 0 {
            timeRemaining = max(0, timeRemaining - timeElapsed)
            while timeRemaining <= 0 && isRunning { finishPhaseInBackground() }
            if isRunning && timeRemaining > 0 {
                startVisualTimer()
                scheduleBackgroundNotification()
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
    }

    // MARK: - Timer Control

    func startTimer() {
        guard !isRunning else { return }
        isRunning = true
        lastActiveTime = Date().timeIntervalSince1970

        if timeRemaining <= 0 { finishPhase(); return }
        startVisualTimer()
        scheduleBackgroundNotification()
    }

    private func startVisualTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= tickInterval
                if timeRemaining <= 0 { finishPhase() }
            } else { finishPhase() }
        }
        if let t = timer { RunLoop.current.add(t, forMode: .common) }
    }

    func pauseTimer() {
        isRunning = false
        timer?.invalidate(); timer = nil
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
        startTimer() // auto-start next phase
    }

    // MARK: - Background Notifications

    private func scheduleBackgroundNotification() {
        let center = UNUserNotificationCenter.current()
        cancelBackgroundNotifications()
        guard timeRemaining > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Pomodoro Timer"
        content.body = timerType == "Work"
            ? "\(workLabel) session complete! Time for \(breakLabel.lowercased())."
            : "\(breakLabel) over! Ready for \(workLabel.lowercased())?"
        content.sound = .default
        content.badge = 1

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, timeRemaining), repeats: false)
        let request = UNNotificationRequest(identifier: "pomodoroPhaseComplete", content: content, trigger: trigger)
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
        if UIApplication.shared.applicationState == .active {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
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
