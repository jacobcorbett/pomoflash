import SwiftUI

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
