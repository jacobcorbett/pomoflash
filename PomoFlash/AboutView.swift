import SwiftUI

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
