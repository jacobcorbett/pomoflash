import SwiftUI

private extension Bundle {
    var appName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "App"
    }
    var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
    var appBuild: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
    var appDeveloper: String {
        object(forInfoDictionaryKey: "AppDeveloperName") as? String ?? "Jacob Corbett"
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                LabeledContent("App", value: Bundle.main.appName)
                LabeledContent("Version", value: "\(Bundle.main.appVersion) (\(Bundle.main.appBuild))")
                LabeledContent("Made with", value: "SwiftUI")
                LabeledContent("Developed by", value: Bundle.main.appDeveloper)
            }
        }
        .navigationTitle("About")
    }
}

#Preview { AboutView() }
