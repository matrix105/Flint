import SwiftUI
import SwiftData
import Combine

// MARK: - SwiftData Nutrition Models

@Model
final class FoodItemData {
    var id: UUID
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
    var timestamp: Date
    @Relationship(inverse: \MealData.items) var meal: MealData?

    init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double, servingSize: String = "", timestamp: Date = .now) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.timestamp = timestamp
    }

    var macros: MacroNutrients {
        MacroNutrients(calories: calories, protein: protein, carbs: carbs, fat: fat)
    }
}

@Model
final class MealData {
    var id: UUID
    var name: String
    var timestamp: Date
    @Relationship(deleteRule: .cascade) var items: [FoodItemData]
    @Relationship(inverse: \DailyLogData.meals) var dailyLog: DailyLogData?

    init(name: String, items: [FoodItemData] = [], timestamp: Date = .now) {
        self.id = UUID()
        self.name = name
        self.items = items
        self.timestamp = timestamp
    }

    var totalMacros: MacroNutrients {
        items.reduce(into: MacroNutrients.zero) { result, item in
            result.calories += item.calories
            result.protein += item.protein
            result.carbs += item.carbs
            result.fat += item.fat
        }
    }
}

@Model
final class DailyLogData {
    var id: UUID
    var date: Date
    @Relationship(deleteRule: .cascade) var meals: [MealData]
    var waterIntake: Double

    init(date: Date = .now, meals: [MealData] = [], waterIntake: Double = 0) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.meals = meals
        self.waterIntake = waterIntake
    }

    var totalMacros: MacroNutrients {
        meals.reduce(into: MacroNutrients.zero) { result, meal in
            let m = meal.totalMacros
            result.calories += m.calories
            result.protein += m.protein
            result.carbs += m.carbs
            result.fat += m.fat
        }
    }
}

@Model
final class UserProfileData {
    var id: UUID
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var goalWeight: Double?
    var sexRaw: String
    var activityLevelRaw: String
    var dietaryGoalRaw: String
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init(name: String = "", age: Int = 25, heightCm: Double = 170, weightKg: Double = 70, goalWeight: Double? = nil, sex: UserProfile.Sex = .male, activityLevel: UserProfile.ActivityLevel = .moderatelyActive, dietaryGoal: UserProfile.DietaryGoal = .maintain) {
        self.id = UUID()
        self.name = name
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.goalWeight = goalWeight
        self.sexRaw = sex.rawValue
        self.activityLevelRaw = activityLevel.rawValue
        self.dietaryGoalRaw = dietaryGoal.rawValue
        self.hasCompletedOnboarding = false
        self.createdAt = .now
    }

    var sex: UserProfile.Sex {
        get { UserProfile.Sex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }

    var activityLevel: UserProfile.ActivityLevel {
        get { UserProfile.ActivityLevel(rawValue: activityLevelRaw) ?? .moderatelyActive }
        set { activityLevelRaw = newValue.rawValue }
    }

    var dietaryGoal: UserProfile.DietaryGoal {
        get { UserProfile.DietaryGoal(rawValue: dietaryGoalRaw) ?? .maintain }
        set { dietaryGoalRaw = newValue.rawValue }
    }
}

@Model
final class FlintBadgeData {
    var id: String
    var name: String
    var badgeDescription: String
    var iconName: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var category: String
    var xpReward: Int

    init(id: String, name: String, description: String, iconName: String, category: String = "general", xpReward: Int = 50) {
        self.id = id
        self.name = name
        self.badgeDescription = description
        self.iconName = iconName
        self.isUnlocked = false
        self.unlockedDate = nil
        self.category = category
        self.xpReward = xpReward
    }
}

@Model
final class WeeklyChallengeData {
    var id: UUID
    var title: String
    var challengeDescription: String
    var target: Int
    var current: Int
    var startDate: Date
    var endDate: Date
    var xpReward: Int
    var isCompleted: Bool

    init(title: String, description: String, target: Int, xpReward: Int = 200) {
        self.id = UUID()
        self.title = title
        self.challengeDescription = description
        self.target = target
        self.current = 0
        self.startDate = .now
        self.endDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
        self.xpReward = xpReward
        self.isCompleted = false
    }

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }
}

@Model
final class StreakData {
    var id: UUID
    var currentStreak: Int
    var longestStreak: Int
    var lastLogDate: Date?

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastLogDate = nil
    }
}

// MARK: - Value Types (non-persisted)

struct MacroNutrients: Codable, Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let zero = MacroNutrients(calories: 0, protein: 0, carbs: 0, fat: 0)

    static func + (lhs: MacroNutrients, rhs: MacroNutrients) -> MacroNutrients {
        MacroNutrients(
            calories: lhs.calories + rhs.calories,
            protein: lhs.protein + rhs.protein,
            carbs: lhs.carbs + rhs.carbs,
            fat: lhs.fat + rhs.fat
        )
    }
}

struct NutritionTarget: Codable, Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let `default` = NutritionTarget(calories: 2000, protein: 150, carbs: 200, fat: 65)

    static func calculate(for profile: UserProfileData) -> NutritionTarget {
        // Mifflin-St Jeor equation
        let bmr: Double
        let weightKg = profile.weightKg
        let heightCm = profile.heightCm
        let age = Double(profile.age)

        switch profile.sex {
        case .male:
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * age + 5
        case .female:
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * age - 161
        }

        let activityMultiplier: Double
        switch profile.activityLevel {
        case .sedentary: activityMultiplier = 1.2
        case .lightlyActive: activityMultiplier = 1.375
        case .moderatelyActive: activityMultiplier = 1.55
        case .veryActive: activityMultiplier = 1.725
        case .extremelyActive: activityMultiplier = 1.9
        }

        let tdee = bmr * activityMultiplier

        let goalCalories: Double
        switch profile.dietaryGoal {
        case .lose: goalCalories = tdee - 500
        case .maintain: goalCalories = tdee
        case .gain: goalCalories = tdee + 300
        }

        let proteinGrams: Double
        switch profile.dietaryGoal {
        case .lose: proteinGrams = weightKg * 2.2
        case .maintain: proteinGrams = weightKg * 1.8
        case .gain: proteinGrams = weightKg * 2.0
        }

        let fatCalories = goalCalories * 0.25
        let fatGrams = fatCalories / 9
        let proteinCalories = proteinGrams * 4
        let carbCalories = goalCalories - proteinCalories - fatCalories
        let carbGrams = max(0, carbCalories / 4)

        return NutritionTarget(
            calories: round(goalCalories),
            protein: round(proteinGrams),
            carbs: round(carbGrams),
            fat: round(fatGrams)
        )
    }
}

// MARK: - Nutrition Store (Observable wrapper)

@MainActor
class NutritionStore: ObservableObject {
    @Published var todayMacros: MacroNutrients = .zero
    @Published var todayMeals: [MealData] = []
    @Published var target: NutritionTarget = .default
    @Published var streak: Int = 0
    @Published var flintXP: Int = 0
    @Published var flintLevel: Int = 1
    @Published var waterIntake: Double = 0

    var modelContext: ModelContext?

    func configure(with context: ModelContext) {
        self.modelContext = context
        loadToday()
        loadGamification()
    }

    func loadToday() {
        guard let context = modelContext else { return }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<DailyLogData> { $0.date == startOfDay }
        let descriptor = FetchDescriptor<DailyLogData>(predicate: predicate)

        if let logs = try? context.fetch(descriptor), let todayLog = logs.first {
            todayMeals = todayLog.meals
            todayMacros = todayLog.totalMacros
            waterIntake = todayLog.waterIntake
        }
    }

    func loadGamification() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<StreakData>()
        if let streaks = try? context.fetch(descriptor), let data = streaks.first {
            streak = data.currentStreak
        }

        // Calculate XP from unlocked badges
        let badgeDescriptor = FetchDescriptor<FlintBadgeData>(predicate: #Predicate { $0.isUnlocked })
        if let badges = try? context.fetch(badgeDescriptor) {
            flintXP = badges.reduce(0) { $0 + $1.xpReward }
        }
        flintLevel = max(1, flintXP / 500 + 1)
    }

    func logMeal(name: String, items: [FoodItemData]) {
        guard let context = modelContext else { return }

        let meal = MealData(name: name, items: items)
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<DailyLogData> { $0.date == startOfDay }
        let descriptor = FetchDescriptor<DailyLogData>(predicate: predicate)

        let dailyLog: DailyLogData
        if let logs = try? context.fetch(descriptor), let existing = logs.first {
            dailyLog = existing
        } else {
            dailyLog = DailyLogData(date: .now)
            context.insert(dailyLog)
        }

        dailyLog.meals.append(meal)
        try? context.save()
        loadToday()
        updateStreak()
        syncToWatch()
    }

    func deleteMeal(_ meal: MealData) {
        guard let context = modelContext else { return }
        context.delete(meal)
        try? context.save()
        loadToday()
        syncToWatch()
    }

    func loadProfile() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<UserProfileData>()
        if let profile = (try? context.fetch(descriptor))?.first {
            target = NutritionTarget.calculate(for: profile)
        }
    }

    private func syncToWatch() {
        let lastMeal = todayMeals.last.map { meal -> (name: String, time: String, calories: Int) in
            (meal.name, meal.timestamp.formatted(date: .omitted, time: .shortened), Int(meal.totalMacros.calories))
        }
        WatchConnectivityManager.shared.syncTodayToWatch(
            calories: todayMacros.calories,
            target: target.calories,
            protein: todayMacros.protein,
            proteinTarget: target.protein,
            carbs: todayMacros.carbs,
            carbsTarget: target.carbs,
            fat: todayMacros.fat,
            fatTarget: target.fat,
            streak: streak,
            lastMeal: lastMeal
        )
    }

    func addWater(_ amount: Double) {
        guard let context = modelContext else { return }
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let predicate = #Predicate<DailyLogData> { $0.date == startOfDay }
        let descriptor = FetchDescriptor<DailyLogData>(predicate: predicate)

        if let logs = try? context.fetch(descriptor), let todayLog = logs.first {
            todayLog.waterIntake += amount
        } else {
            let log = DailyLogData(date: .now, waterIntake: amount)
            context.insert(log)
        }
        try? context.save()
        loadToday()
    }

    private func updateStreak() {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<StreakData>()
        let streakData: StreakData

        if let existing = try? context.fetch(descriptor), let data = existing.first {
            streakData = data
        } else {
            streakData = StreakData()
            context.insert(streakData)
        }

        let today = Calendar.current.startOfDay(for: .now)
        if let lastDate = streakData.lastLogDate {
            let lastDay = Calendar.current.startOfDay(for: lastDate)
            let dayDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if dayDiff == 1 {
                streakData.currentStreak += 1
            } else if dayDiff > 1 {
                streakData.currentStreak = 1
            }
        } else {
            streakData.currentStreak = 1
        }

        streakData.lastLogDate = .now
        streakData.longestStreak = max(streakData.longestStreak, streakData.currentStreak)
        try? context.save()
        streak = streakData.currentStreak
    }
}

// MARK: - UserProfile (enums used by UserProfileData + OnboardingView)

struct UserProfile: Codable {
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var goalWeight: Double?
    var activityLevel: ActivityLevel
    var dietaryGoal: DietaryGoal

    enum Sex: String, Codable, CaseIterable {
        case male = "Male"
        case female = "Female"
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary = "Sedentary"
        case lightlyActive = "Lightly Active"
        case moderatelyActive = "Moderately Active"
        case veryActive = "Very Active"
        case extremelyActive = "Extremely Active"
    }

    enum DietaryGoal: String, Codable, CaseIterable {
        case lose = "Fat Loss"
        case maintain = "Maintain"
        case gain = "Muscle Gain"
    }
}
