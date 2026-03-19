import SwiftUI
import SwiftData

@main
struct FlintApp: App {
    @State private var auth = AuthenticationManager()
    @StateObject private var healthManager = HealthManager()
    @StateObject private var nutritionStore = NutritionStore()
    @StateObject private var gamificationEngine = GamificationEngine()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FoodItemData.self,
            MealData.self,
            DailyLogData.self,
            UserProfileData.self,
            FlintBadgeData.self,
            WeeklyChallengeData.self,
            StreakData.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            groupContainer: .identifier("group.com.flint.nutrition")
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else if !auth.isUnlocked && auth.hasPIN {
                    LockScreenView()
                } else {
                    ContentView()
                }
            }
            .environment(auth)
            .environmentObject(healthManager)
            .environmentObject(nutritionStore)
            .environmentObject(gamificationEngine)
            .preferredColorScheme(.dark)
            .onAppear {
                let context = sharedModelContainer.mainContext
                nutritionStore.configure(with: context)
                gamificationEngine.configure(with: context)
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .background:
                    if auth.hasPIN { auth.lock() }
                case .active:
                    if auth.hasPIN && !auth.isUnlocked {
                        Task { _ = await auth.authenticateWithBiometrics() }
                    }
                    Task { await healthManager.fetchAllTodayData() }
                default:
                    break
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
