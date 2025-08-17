import SwiftUI

struct ProfileView: View {
    @AppStorage("displayName") private var displayName = "You"

    var body: some View {
        NavigationView {
            List {
                // Header
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

                // ✅ Where the settings live now
                Section("Timer") {
                    NavigationLink {
                        TimerSettingsView()
                    } label: {
                        Label("Timer Settings", systemImage: "slider.horizontal.3")
                    }
                }

                Section("Developer") {
                    NavigationLink {
                        DevToolsView()
                    } label: {
                        Label("Dev Tools", systemImage: "wrench.and.screwdriver")
                    }
                }

                Section("About") {
                    NavigationLink { AboutView() } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple],
                                     startPoint: .topLeading,
                                     endPoint: .bottomTrailing))
                .frame(width: 64, height: 64)
            Text(initials(from: displayName))
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .accessibilityLabel("Profile picture")
    }

    private func initials(from name: String) -> String {
        let parts = name.split(whereSeparator: { $0.isWhitespace })
        let letters = parts.prefix(2).map { String($0.prefix(1)).uppercased() }
        return letters.joined().isEmpty ? "Y" : letters.joined()
    }
}
