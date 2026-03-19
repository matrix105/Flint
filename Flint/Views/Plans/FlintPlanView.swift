import SwiftUI

struct FlintPlanView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @StateObject private var planEngine = FlintPlanEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Plan status
                    VStack(spacing: 8) {
                        Image(systemName: "sparkle")
                            .font(.largeTitle)
                            .foregroundColor(.flintSpark)

                        Text("Flint Plan")
                            .font(.flintBody(20, weight: .bold))
                            .foregroundColor(.flintText)

                        Text("Your personalised daily meal plan, adapted to your activity and goals.")
                            .font(.flintBody(14))
                            .foregroundColor(.flintGrey)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                    // Generate button
                    Button {
                        Task {
                            _ = await planEngine.generatePlan(
                                target: nutritionStore.target,
                                consumed: nutritionStore.todayLog.totalMacros,
                                activityLevel: "moderate"
                            )
                        }
                    } label: {
                        HStack {
                            if planEngine.isGenerating {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(planEngine.isGenerating ? "Generating..." : "Generate Plan")
                                .font(.flintBody(16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.flintSpark)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(planEngine.isGenerating)
                    .padding(.horizontal)

                    // Remaining macros
                    RemainingMacrosCard(
                        consumed: nutritionStore.todayLog.totalMacros,
                        target: nutritionStore.target
                    )

                    Spacer()
                }
            }
            .background(Color.flintBlack)
            .navigationTitle("Flint Plan")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct RemainingMacrosCard: View {
    let consumed: MacroNutrients
    let target: NutritionTarget

    var body: some View {
        VStack(spacing: 12) {
            Text("Remaining Today")
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintGrey)

            HStack(spacing: 20) {
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

#Preview {
    FlintPlanView()
        .environmentObject(NutritionStore())
}
