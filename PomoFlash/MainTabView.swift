import SwiftUI

struct MainTabView: View {
    @State private var selection = 1 // start on Timer

    var body: some View {
        TabView(selection: $selection) {
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                .tag(0)

            TimerView() // Timer
                .tabItem { Label("Timer", systemImage: "timer") }
                .tag(1)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(2)
        }
    }
}
