import SwiftUI

@main
struct FlintApp: App {
    @StateObject private var healthManager = HealthManager()
    @StateObject private var nutritionStore = NutritionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
                .environmentObject(nutritionStore)
                .preferredColorScheme(.dark)
        }
    }
}
