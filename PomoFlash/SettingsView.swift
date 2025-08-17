import SwiftUI

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
                // WORK
                Section("Work Session") {
                    HStack {
                        Text("Label:")
                        TextField("Work", text: $workLabel)
                            .textFieldStyle(.roundedBorder)
                    }

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
                Section("Break Session") {
                    HStack {
                        Text("Label:")
                        TextField("Break", text: $breakLabel)
                            .textFieldStyle(.roundedBorder)
                    }

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

                // Dev Tools
                Section("Dev Tools") {
                    Button("Reset Everything", role: .destructive) { showResetAlert = true }
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
