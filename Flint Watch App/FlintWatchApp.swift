import SwiftUI
import WatchConnectivity

@main
struct FlintWatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchDashboardView()
                    .environmentObject(connectivityManager)
            }
        }
    }
}
