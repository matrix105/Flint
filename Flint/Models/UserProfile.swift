import Foundation

struct UserProfile: Codable {
    var name: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var goalWeight: Double?
    var activityLevel: ActivityLevel
    var dietaryGoal: DietaryGoal

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

// MARK: - Gamification

struct FlintBadge: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    var isUnlocked: Bool
    var unlockedDate: Date?
}

struct WeeklyFlintChallenge: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    var target: Int
    var current: Int
    var startDate: Date
    var endDate: Date

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(current) / Double(target), 1.0)
    }

    var isComplete: Bool {
        current >= target
    }
}
