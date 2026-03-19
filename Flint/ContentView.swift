import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today = "Today"
        case log = "Log"
        case plan = "Flint Plan"
        case progress = "Progress"
        case profile = "Profile"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Today", systemImage: "flame.fill")
                }
                .tag(Tab.today)

            LogFoodView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
                .tag(Tab.log)

            FlintPlanView()
                .tabItem {
                    Label("Plan", systemImage: "calendar")
                }
                .tag(Tab.plan)

            ProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.progress)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(.flintSpark)
    }
}

#Preview {
    ContentView()
}
