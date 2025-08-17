import SwiftUI

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
