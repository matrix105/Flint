import SwiftUI

struct VariationsView: View {
    let mealName: String
    let targetMacros: MacroNutrients
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @StateObject private var planEngine = FlintPlanEngine()
    @Environment(\.dismiss) private var dismiss
    @State private var showLogSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Alternatives for")
                        .font(.flintBody(14))
                        .foregroundColor(.flintGrey)
                    Text(mealName)
                        .font(.flintBody(17, weight: .semibold))
                        .foregroundColor(.flintText)

                    let variations = planEngine.generateVariations(
                        for: inferMealType(),
                        target: targetMacros,
                        count: 3
                    )

                    if variations.isEmpty {
                        Text("No variations available.")
                            .font(.flintBody(14))
                            .foregroundColor(.flintStone)
                            .padding(.top, 40)
                    } else {
                        VariationCard(
                            emoji: "💪",
                            label: "High Protein",
                            meal: variations.count > 0 ? variations[0] : nil,
                            onLog: logVariation
                        )

                        if variations.count > 1 {
                            VariationCard(
                                emoji: "🪶",
                                label: "Lower Calorie",
                                meal: variations[1],
                                onLog: logVariation
                            )
                        }

                        if variations.count > 2 {
                            VariationCard(
                                emoji: "⚡",
                                label: "Quick Version",
                                meal: variations[2],
                                onLog: logVariation
                            )
                        }

                        if showLogSuccess {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.flintSuccess)
                                Text("Meal logged!")
                                    .font(.flintBody(14, weight: .medium))
                                    .foregroundColor(.flintSuccess)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Variations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.flintSpark)
                }
            }
        }
    }

    private func inferMealType() -> String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 10 { return "Breakfast" }
        else if hour < 14 { return "Lunch" }
        else if hour < 18 { return "Dinner" }
        else { return "Snack" }
    }

    private func logVariation(_ meal: FlintPlanEngine.PlannedMeal) {
        let foodItems = meal.items.map { itemName in
            let count = Double(max(1, meal.items.count))
            return FoodItemData(
                name: itemName,
                calories: meal.macros.calories / count,
                protein: meal.macros.protein / count,
                carbs: meal.macros.carbs / count,
                fat: meal.macros.fat / count
            )
        }

        nutritionStore.logMeal(name: meal.name, items: foodItems)
        gamificationEngine.evaluateAfterMealLog(
            todayMacros: nutritionStore.todayMacros,
            target: nutritionStore.target,
            mealCount: nutritionStore.todayMeals.count,
            streak: nutritionStore.streak
        )
        gamificationEngine.updateChallengeProgress()

        withAnimation { showLogSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showLogSuccess = false }
            dismiss()
        }
    }
}

struct VariationCard: View {
    let emoji: String
    let label: String
    let meal: FlintPlanEngine.PlannedMeal?
    let onLog: (FlintPlanEngine.PlannedMeal) -> Void

    var body: some View {
        if let meal {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(emoji) \(label)")
                        .font(.flintBody(15, weight: .semibold))
                        .foregroundColor(.flintText)
                    Spacer()
                }

                Text(meal.name)
                    .font(.flintBody(14, weight: .medium))
                    .foregroundColor(.flintText)

                Text(meal.items.joined(separator: ", "))
                    .font(.flintBody(13))
                    .foregroundColor(.flintGrey)

                HStack(spacing: 16) {
                    MacroPill(value: "\(Int(meal.macros.calories))", label: "kcal", color: .flintSpark)
                    MacroPill(value: "\(Int(meal.macros.protein))g", label: "P", color: .flintProtein)
                    MacroPill(value: "\(Int(meal.macros.carbs))g", label: "C", color: .flintCarbs)
                    MacroPill(value: "\(Int(meal.macros.fat))g", label: "F", color: .flintFat)
                }

                Button {
                    onLog(meal)
                } label: {
                    Text("Log This")
                        .font(.flintBody(14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.flintSpark)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            .background(Color.flintSurface)
            .cornerRadius(16)
        }
    }
}

struct MacroPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.flintMono(13))
                .foregroundColor(color)
            Text(label)
                .font(.flintBody(10))
                .foregroundColor(.flintStone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.flintElevated)
        .cornerRadius(8)
    }
}
