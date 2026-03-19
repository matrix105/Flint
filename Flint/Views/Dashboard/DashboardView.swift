import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    DashboardHeader()

                    // Calorie ring
                    CalorieRingView(
                        consumed: nutritionStore.todayLog.totalMacros.calories,
                        target: nutritionStore.target.calories,
                        burned: healthManager.activeCalories
                    )

                    // Macro bars
                    MacroBarStack(
                        macros: nutritionStore.todayLog.totalMacros,
                        target: nutritionStore.target
                    )

                    // Today's meals
                    TodayMealsSection(meals: nutritionStore.todayLog.meals)

                    // Quick actions
                    QuickActionsRow()
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Dashboard Header

struct DashboardHeader: View {
    var body: some View {
        HStack {
            Image(systemName: "sparkle")
                .foregroundColor(.flintSpark)
                .font(.title2)
            Text("Flint")
                .font(.flintBody(20, weight: .semibold))
                .foregroundColor(.flintText)
            Spacer()
            NavigationLink(destination: ProfileView()) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.flintGrey)
            }
        }
    }
}

// MARK: - Calorie Ring

struct CalorieRingView: View {
    let consumed: Double
    let target: Double
    let burned: Double

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    private var remaining: Double {
        max(0, target - consumed + burned)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.flintSpark.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.flintSpark, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(Int(remaining))")
                        .font(.flintDisplay(36))
                        .foregroundColor(.flintText)
                    Text("kcal remaining")
                        .font(.flintBody(12))
                        .foregroundColor(.flintGrey)
                }
            }
            .frame(width: 180, height: 180)

            HStack(spacing: 24) {
                CalorieStat(label: "Consumed", value: Int(consumed), color: .flintSpark)
                CalorieStat(label: "Burned", value: Int(burned), color: .flintSuccess)
                CalorieStat(label: "Target", value: Int(target), color: .flintGrey)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct CalorieStat: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.flintMono(16))
                .foregroundColor(color)
            Text(label)
                .font(.flintBody(11))
                .foregroundColor(.flintStone)
        }
    }
}

// MARK: - Macro Bars

struct MacroBarStack: View {
    let macros: MacroNutrients
    let target: NutritionTarget

    var body: some View {
        VStack(spacing: 12) {
            MacroBar(label: "Protein", current: macros.protein, target: target.protein, unit: "g", color: .flintProtein)
            MacroBar(label: "Carbs", current: macros.carbs, target: target.carbs, unit: "g", color: .flintCarbs)
            MacroBar(label: "Fat", current: macros.fat, target: target.fat, unit: "g", color: .flintFat)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct MacroBar: View {
    let label: String
    let current: Double
    let target: Double
    let unit: String
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.flintBody(13, weight: .medium))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(Int(current))/\(Int(target))\(unit)")
                    .font(.flintMono(13))
                    .foregroundColor(.flintGrey)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Today's Meals

struct TodayMealsSection: View {
    let meals: [Meal]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)

            if meals.isEmpty {
                Text("No meals logged yet. Tap Log to get started.")
                    .font(.flintBody(13))
                    .foregroundColor(.flintStone)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(meals) { meal in
                    MealRow(meal: meal)
                }
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct MealRow: View {
    let meal: Meal

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(meal.name)
                    .font(.flintBody(14, weight: .medium))
                    .foregroundColor(.flintText)
                Text("\(meal.items.count) items")
                    .font(.flintBody(12))
                    .foregroundColor(.flintStone)
            }
            Spacer()
            Text("\(Int(meal.totalMacros.calories)) kcal")
                .font(.flintMono(14))
                .foregroundColor(.flintGrey)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quick Actions

struct QuickActionsRow: View {
    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(title: "Quick Log", icon: "bolt.fill", color: .flintSpark)
            QuickActionButton(title: "Flint Scan", icon: "camera.fill", color: .flintProtein)
            QuickActionButton(title: "Water", icon: "drop.fill", color: .flintSuccess)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(title)
                .font(.flintBody(11))
                .foregroundColor(.flintGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.flintSurface)
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .environmentObject(NutritionStore())
        .environmentObject(HealthManager())
}
