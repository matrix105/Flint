import SwiftUI
import SwiftData

// MARK: - Gamification Engine

@MainActor
class GamificationEngine: ObservableObject {
    @Published var badges: [FlintBadgeData] = []
    @Published var currentChallenge: WeeklyChallengeData?
    @Published var streak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var totalXP: Int = 0
    @Published var level: Int = 1
    @Published var recentUnlock: FlintBadgeData?

    private var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadAll()
    }

    func loadAll() {
        loadBadges()
        loadStreak()
        loadChallenge()
        calculateXPAndLevel()
    }

    // MARK: - Badges

    private func loadBadges() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<FlintBadgeData>(sortBy: [SortDescriptor(\.category)])
        badges = (try? context.fetch(descriptor)) ?? []
    }

    func checkAndUnlockBadge(id: String) {
        guard let context = modelContext,
              let badge = badges.first(where: { $0.id == id && !$0.isUnlocked }) else { return }

        badge.isUnlocked = true
        badge.unlockedDate = .now
        try? context.save()
        recentUnlock = badge
        loadBadges()
        calculateXPAndLevel()
    }

    // MARK: - Streak

    private func loadStreak() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<StreakData>()
        if let data = (try? context.fetch(descriptor))?.first {
            streak = data.currentStreak
            longestStreak = data.longestStreak
        }
    }

    // MARK: - Weekly Challenge

    private func loadChallenge() {
        guard let context = modelContext else { return }
        let now = Date()
        let predicate = #Predicate<WeeklyChallengeData> { $0.endDate > now && !$0.isCompleted }
        let descriptor = FetchDescriptor<WeeklyChallengeData>(predicate: predicate)
        currentChallenge = (try? context.fetch(descriptor))?.first

        // Auto-generate if none active
        if currentChallenge == nil {
            generateWeeklyChallenge()
        }
    }

    func updateChallengeProgress(increment: Int = 1) {
        guard let challenge = currentChallenge else { return }
        challenge.current += increment
        if challenge.current >= challenge.target {
            challenge.isCompleted = true
            totalXP += challenge.xpReward
            checkAndUnlockBadge(id: "weekly_warrior")
        }
        try? modelContext?.save()
        loadChallenge()
        calculateXPAndLevel()
    }

    private func generateWeeklyChallenge() {
        guard let context = modelContext else { return }

        let challenges = [
            ("Protein Champion", "Hit your protein target every day this week.", 7),
            ("Hydration Hero", "Drink 2L+ water every day this week.", 7),
            ("Meal Prep Master", "Log all 3 meals for 5 days this week.", 5),
            ("Streak Builder", "Log at least one meal every day this week.", 7),
            ("Macro Balance", "Stay within 10% of all macro targets for 4 days.", 4),
            ("Early Bird", "Log breakfast before 9am for 5 days.", 5),
            ("Clean Eating", "Log 5 meals with protein > 30g.", 5),
        ]

        let pick = challenges.randomElement() ?? challenges[0]
        let challenge = WeeklyChallengeData(title: pick.0, description: pick.1, target: pick.2)
        context.insert(challenge)
        try? context.save()
        currentChallenge = challenge
    }

    // MARK: - XP & Level

    private func calculateXPAndLevel() {
        let badgeXP = badges.filter(\.isUnlocked).reduce(0) { $0 + $1.xpReward }
        let challengeXP: Int
        if let context = modelContext {
            let predicate = #Predicate<WeeklyChallengeData> { $0.isCompleted }
            let descriptor = FetchDescriptor<WeeklyChallengeData>(predicate: predicate)
            challengeXP = ((try? context.fetch(descriptor)) ?? []).reduce(0) { $0 + $1.xpReward }
        } else {
            challengeXP = 0
        }

        // Streak XP: 10 per day
        let streakXP = streak * 10

        totalXP = badgeXP + challengeXP + streakXP
        level = max(1, totalXP / 500 + 1)
    }

    // MARK: - Auto-check achievements after logging

    func evaluateAfterMealLog(todayMacros: MacroNutrients, target: NutritionTarget, mealCount: Int, streak: Int) {
        // First meal
        if mealCount == 1 { checkAndUnlockBadge(id: "first_spark") }

        // Protein target hit
        if todayMacros.protein >= target.protein { checkAndUnlockBadge(id: "protein_pro") }

        // All macros on target (within 10%)
        let calClose = abs(todayMacros.calories - target.calories) / target.calories < 0.1
        let proClose = abs(todayMacros.protein - target.protein) / target.protein < 0.1
        let carbClose = abs(todayMacros.carbs - target.carbs) / target.carbs < 0.1
        let fatClose = abs(todayMacros.fat - target.fat) / target.fat < 0.1
        if calClose && proClose && carbClose && fatClose { checkAndUnlockBadge(id: "macro_master") }

        // Streak badges
        if streak >= 3 { checkAndUnlockBadge(id: "streak_3") }
        if streak >= 7 { checkAndUnlockBadge(id: "streak_7") }
        if streak >= 14 { checkAndUnlockBadge(id: "streak_14") }
        if streak >= 30 { checkAndUnlockBadge(id: "streak_30") }
        if streak >= 60 { checkAndUnlockBadge(id: "streak_60") }
        if streak >= 100 { checkAndUnlockBadge(id: "streak_100") }
        if streak >= 365 { checkAndUnlockBadge(id: "streak_365") }

        // Meal count badges
        let totalMeals = countTotalMeals()
        if totalMeals >= 10 { checkAndUnlockBadge(id: "meals_10") }
        if totalMeals >= 50 { checkAndUnlockBadge(id: "meals_50") }
        if totalMeals >= 100 { checkAndUnlockBadge(id: "meals_100") }
        if totalMeals >= 500 { checkAndUnlockBadge(id: "meals_500") }
        if totalMeals >= 1000 { checkAndUnlockBadge(id: "meals_1000") }
    }

    func evaluateAfterWorkout(workoutType: String, weeklyMinutes: Double) {
        checkAndUnlockBadge(id: "first_workout")
        if weeklyMinutes >= 150 { checkAndUnlockBadge(id: "active_week") }
        if weeklyMinutes >= 300 { checkAndUnlockBadge(id: "fitness_beast") }

        switch workoutType.lowercased() {
        case "running": checkAndUnlockBadge(id: "runner")
        case "strength": checkAndUnlockBadge(id: "lifter")
        case "yoga": checkAndUnlockBadge(id: "yogi")
        case "swimming": checkAndUnlockBadge(id: "swimmer")
        case "hiit": checkAndUnlockBadge(id: "hiit_hero")
        default: break
        }
    }

    func evaluateAfterHealthSync(healthContext: HealthContext) {
        if healthContext.sleepHours >= 8 { checkAndUnlockBadge(id: "good_sleep") }
        if healthContext.steps >= 10000 { checkAndUnlockBadge(id: "step_master") }
        if healthContext.vo2Max > 0 { checkAndUnlockBadge(id: "vo2_tracked") }
    }

    private func countTotalMeals() -> Int {
        guard let context = modelContext else { return 0 }
        let descriptor = FetchDescriptor<MealData>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Seed Badges

    static func seedBadges(in context: ModelContext) {
        let allBadges: [(String, String, String, String, String, Int)] = [
            // (id, name, description, icon, category, xpReward)
            // Getting Started (5)
            ("first_spark", "First Spark", "Log your first meal", "flame", "getting_started", 25),
            ("profile_complete", "Identity", "Complete your profile", "person.fill", "getting_started", 25),
            ("health_connected", "Vitals Online", "Connect Apple Health", "heart.fill", "getting_started", 25),
            ("first_scan", "First Scan", "Use Flint Scan for the first time", "viewfinder", "getting_started", 25),
            ("first_plan", "Planner", "Generate your first Flint Plan", "calendar", "getting_started", 25),

            // Streaks (7)
            ("streak_3", "Warming Up", "3-day streak", "flame", "streaks", 50),
            ("streak_7", "On Fire", "7-day streak", "flame.fill", "streaks", 100),
            ("streak_14", "Blazing", "14-day streak", "bolt.fill", "streaks", 150),
            ("streak_30", "Monthly Flame", "30-day streak", "flame.circle.fill", "streaks", 250),
            ("streak_60", "Inferno", "60-day streak", "flame.circle", "streaks", 400),
            ("streak_100", "Centurion", "100-day streak", "star.fill", "streaks", 500),
            ("streak_365", "Year of Fire", "365-day streak", "trophy.fill", "streaks", 1000),

            // Meal Logging (5)
            ("meals_10", "Getting Started", "Log 10 meals", "fork.knife", "logging", 50),
            ("meals_50", "Regular Logger", "Log 50 meals", "fork.knife.circle", "logging", 100),
            ("meals_100", "Dedicated", "Log 100 meals", "fork.knife.circle.fill", "logging", 200),
            ("meals_500", "Committed", "Log 500 meals", "star.circle", "logging", 400),
            ("meals_1000", "Legendary Logger", "Log 1000 meals", "star.circle.fill", "logging", 750),

            // Nutrition (5)
            ("protein_pro", "Protein Pro", "Hit your protein target", "bolt.heart.fill", "nutrition", 50),
            ("macro_master", "Macro Master", "Hit all macro targets within 10%", "target", "nutrition", 100),
            ("deficit_day", "Calorie Control", "Stay in deficit for a full day", "arrow.down.circle", "nutrition", 50),
            ("surplus_day", "Fuel Up", "Hit surplus target for a full day", "arrow.up.circle", "nutrition", 50),
            ("balanced_week", "Balanced Week", "Hit targets 5 out of 7 days", "chart.bar.fill", "nutrition", 200),

            // Fitness (7)
            ("first_workout", "First Move", "Complete your first tracked workout", "figure.run", "fitness", 25),
            ("active_week", "Active Week", "150+ workout minutes in a week", "figure.walk", "fitness", 100),
            ("fitness_beast", "Fitness Beast", "300+ workout minutes in a week", "figure.strengthtraining.traditional", "fitness", 200),
            ("runner", "Runner", "Complete a running workout", "figure.run", "fitness", 50),
            ("lifter", "Lifter", "Complete a strength workout", "dumbbell.fill", "fitness", 50),
            ("yogi", "Yogi", "Complete a yoga session", "figure.yoga", "fitness", 50),
            ("swimmer", "Swimmer", "Complete a swim workout", "figure.pool.swim", "fitness", 50),

            // Health (4)
            ("good_sleep", "Well Rested", "Get 8+ hours of sleep", "bed.double.fill", "health", 50),
            ("step_master", "Step Master", "Hit 10,000 steps in a day", "shoeprints.fill", "health", 50),
            ("vo2_tracked", "VO2 Tracked", "Have a VO2 Max reading", "lungs.fill", "health", 50),
            ("hiit_hero", "HIIT Hero", "Complete a HIIT workout", "bolt.circle.fill", "health", 75),

            // Challenges (3)
            ("weekly_warrior", "Weekly Warrior", "Complete a Weekly Flint challenge", "shield.fill", "challenges", 100),
            ("challenge_3", "Challenger", "Complete 3 Weekly Flint challenges", "shield.checkered", "challenges", 200),
            ("challenge_10", "Challenge Champion", "Complete 10 Weekly Flint challenges", "crown.fill", "challenges", 500),

            // Special (3)
            ("night_owl", "Night Owl", "Log a meal after midnight", "moon.fill", "special", 50),
            ("early_bird", "Early Bird", "Log breakfast before 7am", "sunrise.fill", "special", 50),
            ("water_champ", "Hydration Hero", "Drink 3L+ water in a day", "drop.fill", "special", 75),
        ]

        for (id, name, desc, icon, cat, xp) in allBadges {
            let predicate = #Predicate<FlintBadgeData> { $0.id == id }
            let descriptor = FetchDescriptor<FlintBadgeData>(predicate: predicate)
            let exists = (try? context.fetchCount(descriptor)) ?? 0 > 0
            if !exists {
                let badge = FlintBadgeData(id: id, name: name, description: desc, iconName: icon, category: cat, xpReward: xp)
                context.insert(badge)
            }
        }

        try? context.save()
    }
}
