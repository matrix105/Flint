import SwiftUI
import Combine

// MARK: - Nutrition Data Models

struct MacroNutrients: Codable, Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let zero = MacroNutrients(calories: 0, protein: 0, carbs: 0, fat: 0)
}

struct FoodItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var macros: MacroNutrients
    var servingSize: String
    var timestamp: Date

    init(id: UUID = UUID(), name: String, macros: MacroNutrients, servingSize: String = "", timestamp: Date = .now) {
        self.id = id
        self.name = name
        self.macros = macros
        self.servingSize = servingSize
        self.timestamp = timestamp
    }
}

struct Meal: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [FoodItem]
    var timestamp: Date

    init(id: UUID = UUID(), name: String, items: [FoodItem] = [], timestamp: Date = .now) {
        self.id = id
        self.name = name
        self.items = items
        self.timestamp = timestamp
    }

    var totalMacros: MacroNutrients {
        items.reduce(into: MacroNutrients.zero) { result, item in
            result.calories += item.macros.calories
            result.protein += item.macros.protein
            result.carbs += item.macros.carbs
            result.fat += item.macros.fat
        }
    }
}

struct DailyLog: Identifiable, Codable {
    let id: UUID
    var date: Date
    var meals: [Meal]
    var waterIntake: Double // in ml

    init(id: UUID = UUID(), date: Date = .now, meals: [Meal] = [], waterIntake: Double = 0) {
        self.id = id
        self.date = date
        self.meals = meals
        self.waterIntake = waterIntake
    }

    var totalMacros: MacroNutrients {
        meals.reduce(into: MacroNutrients.zero) { result, meal in
            let mealMacros = meal.totalMacros
            result.calories += mealMacros.calories
            result.protein += mealMacros.protein
            result.carbs += mealMacros.carbs
            result.fat += mealMacros.fat
        }
    }
}

struct NutritionTarget: Codable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    static let `default` = NutritionTarget(calories: 2000, protein: 150, carbs: 200, fat: 65)
}

// MARK: - Nutrition Store

class NutritionStore: ObservableObject {
    @Published var todayLog: DailyLog = DailyLog()
    @Published var target: NutritionTarget = .default
    @Published var streak: Int = 0
    @Published var flintXP: Int = 0
    @Published var flintLevel: Int = 1

    func logMeal(_ meal: Meal) {
        todayLog.meals.append(meal)
    }

    func addWater(_ amount: Double) {
        todayLog.waterIntake += amount
    }
}
