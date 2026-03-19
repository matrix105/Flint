import SwiftUI

struct FlintPlanView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var healthManager: HealthManager
    @StateObject private var planEngine = FlintPlanEngine()
    @State private var showVariations = false
    @State private var selectedMealForVariation: FlintPlanEngine.PlannedMeal?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Plan header
                if planEngine.currentPlan == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 40))
                            .foregroundColor(.flintSpark)

                        Text("Flint Plan")
                            .font(.flintDisplay(24))
                            .foregroundColor(.flintText)

                        Text("Personalised meals adapted to your activity and goals.")
                            .font(.flintBody(14))
                            .foregroundColor(.flintGrey)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                // Remaining macros
                RemainingMacrosCard(
                    consumed: nutritionStore.todayMacros,
                    target: nutritionStore.target
                )

                // Generate / Regenerate button
                Button {
                    Task {
                        _ = await planEngine.generatePlan(
                            target: nutritionStore.target,
                            consumed: nutritionStore.todayMacros,
                            healthContext: healthManager.healthContext()
                        )
                    }
                } label: {
                    HStack {
                        if planEngine.isGenerating {
                            ProgressView().tint(.white)
                        }
                        Text(planEngine.isGenerating ? "Generating..." : (planEngine.currentPlan != nil ? "Regenerate Plan" : "Generate Plan"))
                            .font(.flintBody(16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(planEngine.currentPlan != nil ? Color.flintElevated : Color.flintSpark)
                    .foregroundColor(planEngine.currentPlan != nil ? .flintText : .white)
                    .cornerRadius(12)
                    .overlay(
                        Group {
                            if planEngine.currentPlan != nil {
                                RoundedRectangle(cornerRadius: 12).stroke(Color.flintBorder, lineWidth: 1)
                            }
                        }
                    )
                }
                .disabled(planEngine.isGenerating)
                .padding(.horizontal)

                // Plan results
                if let plan = planEngine.currentPlan {
                    // AI note
                    Text("💡 \(plan.note)")
                        .font(.flintBody(13))
                        .foregroundColor(.flintGrey)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.flintMuted)
                        .cornerRadius(10)
                        .padding(.horizontal)

                    // Meal cards
                    ForEach(plan.meals) { meal in
                        PlanMealCard(meal: meal) {
                            selectedMealForVariation = meal
                            showVariations = true
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.flintBlack)
        .navigationTitle("Flint Plan")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showVariations) {
            if let meal = selectedMealForVariation {
                VariationsView(
                    mealName: meal.name,
                    targetMacros: meal.macros
                )
            }
        }
    }
}

// MARK: - Remaining Macros Card

struct RemainingMacrosCard: View {
    let consumed: MacroNutrients
    let target: NutritionTarget

    var body: some View {
        VStack(spacing: 12) {
            Text("Remaining Today")
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintGrey)

            HStack(spacing: 16) {
                MacroStat(label: "Calories", value: "\(Int(max(0, target.calories - consumed.calories)))", unit: "kcal", color: .flintSpark)
                MacroStat(label: "Protein", value: "\(Int(max(0, target.protein - consumed.protein)))", unit: "g", color: .flintProtein)
                MacroStat(label: "Carbs", value: "\(Int(max(0, target.carbs - consumed.carbs)))", unit: "g", color: .flintCarbs)
                MacroStat(label: "Fat", value: "\(Int(max(0, target.fat - consumed.fat)))", unit: "g", color: .flintFat)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct MacroStat: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.flintDisplay(20))
                .foregroundColor(color)
            Text(unit)
                .font(.flintMono(10))
                .foregroundColor(color.opacity(0.7))
            Text(label)
                .font(.flintBody(10))
                .foregroundColor(.flintStone)
        }
    }
}

// MARK: - Plan Meal Card

struct PlanMealCard: View {
    let meal: FlintPlanEngine.PlannedMeal
    let onVariations: () -> Void

    private var mealEmoji: String {
        switch meal.mealType {
        case "Breakfast": return "☀️"
        case "Lunch": return "🥗"
        case "Dinner": return "🍖"
        case "Snack": return "🥤"
        default: return "🍽️"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Meal type label
            Text(meal.mealType)
                .font(.flintBody(12, weight: .medium))
                .foregroundColor(.flintGrey)

            // Meal name
            HStack {
                Text(mealEmoji)
                Text(meal.name)
                    .font(.flintBody(16, weight: .semibold))
                    .foregroundColor(.flintText)
            }

            // Ingredients
            Text(meal.items.joined(separator: ", "))
                .font(.flintBody(13))
                .foregroundColor(.flintGrey)

            // Macros
            HStack(spacing: 12) {
                Text("\(Int(meal.macros.calories)) kcal")
                    .font(.flintMono(14))
                    .foregroundColor(.flintSpark)
                Text("P:\(Int(meal.macros.protein))g")
                    .font(.flintMono(12))
                    .foregroundColor(.flintProtein)
                Text("C:\(Int(meal.macros.carbs))g")
                    .font(.flintMono(12))
                    .foregroundColor(.flintCarbs)
                Text("F:\(Int(meal.macros.fat))g")
                    .font(.flintMono(12))
                    .foregroundColor(.flintFat)
            }

            // Actions
            HStack(spacing: 10) {
                Button {
                    // Log this meal
                } label: {
                    Text("Log This")
                        .font(.flintBody(13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.flintSpark)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: onVariations) {
                    Text("Variations")
                        .font(.flintBody(13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.flintElevated)
                        .foregroundColor(.flintText)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.flintBorder, lineWidth: 1))
                }
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        FlintPlanView()
            .environmentObject(NutritionStore())
            .environmentObject(HealthManager())
    }
}
