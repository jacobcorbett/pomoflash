import SwiftUI
import AVFoundation

struct ContentView: View {
    @AppStorage("workDuration") private var workDuration = 25 * 60
    @AppStorage("breakDuration") private var breakDuration = 5 * 60
    
    @State private var timeRemaining = 25 * 60
    @State private var isRunning = false
    @State private var timerType = "Work"
    @State private var timer: Timer?
    @State private var sessionsCompleted = 0
    @State private var showingSettings = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var progress: Double {
        let totalTime = timerType == "Work" ? Double(workDuration) : Double(breakDuration)
        return totalTime > 0 ? 1 - (Double(timeRemaining) / totalTime) : 1
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
                        .rotationEffect(Angle(degrees: -90))
                    
                    Text(formatTime(timeRemaining))
                        .font(.system(size: 48, weight: .bold, design: .monospaced))
                }
                .frame(width: 200, height: 200)
                
                HStack(spacing: 20) {
                    Button(isRunning ? "Pause" : "Start") {
                        if isRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Reset Timer") {
                        resetTimer()
                    }
                    .buttonStyle(.bordered)
                }
                
                Button("Reset Everything") {
                    resetEverything()
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                
                Text("Sessions Completed: \(sessionsCompleted)")
                    .font(.headline)
            }
            .padding()
            .navigationTitle("Pomodoro")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(workDuration: $workDuration, breakDuration: $breakDuration, onSave: {
                    resetEverything()
                })
            }
        }
        .onAppear {
            timeRemaining = workDuration
        }
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                isRunning = false
                playSound()
                
                if timerType == "Work" {
                    timerType = "Break"
                    timeRemaining = breakDuration
                    sessionsCompleted += 1
                } else {
                    timerType = "Work"
                    timeRemaining = workDuration
                }
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = timerType == "Work" ? workDuration : breakDuration
    }
    
    func resetEverything() {
        pauseTimer()
        timerType = "Work"
        timeRemaining = workDuration
        sessionsCompleted = 0
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Stepper("Work Minutes: \(workDuration / 60)", value: Binding(
                    get: { workDuration / 60 },
                    set: { workDuration = $0 * 60 + workDuration % 60 }
                ), in: 0...120)
                
                Stepper("Work Seconds: \(workDuration % 60)", value: Binding(
                    get: { workDuration % 60 },
                    set: { workDuration = (workDuration / 60) * 60 + $0 }
                ), in: 0...59)
                
                Stepper("Break Minutes: \(breakDuration / 60)", value: Binding(
                    get: { breakDuration / 60 },
                    set: { breakDuration = $0 * 60 + breakDuration % 60 }
                ), in: 0...60)
                
                Stepper("Break Seconds: \(breakDuration % 60)", value: Binding(
                    get: { breakDuration % 60 },
                    set: { breakDuration = (breakDuration / 60) * 60 + $0 }
                ), in: 0...59)
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
