import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var gamificationEngine: GamificationEngine

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    DashboardHeader()

                    // Calorie ring
                    CalorieRingView(
                        consumed: nutritionStore.todayMacros.calories,
                        target: nutritionStore.target.calories,
                        burned: healthManager.activeCalories
                    )

                    // Health Snapshot
                    HealthSnapshotView()

                    // Macro bars
                    MacroBarStack(
                        macros: nutritionStore.todayMacros,
                        target: nutritionStore.target
                    )

                    // Streak + Level
                    StreakLevelBar(
                        streak: gamificationEngine.streak,
                        level: gamificationEngine.level,
                        xp: gamificationEngine.totalXP
                    )

                    // Weekly Challenge
                    if let challenge = gamificationEngine.currentChallenge {
                        NavigationLink(destination: WeeklyFlintDetailView()) {
                            WeeklyChallengeMiniCard(challenge: challenge)
                        }
                    }

                    // Flint Plan button
                    NavigationLink(destination: FlintPlanView()) {
                        HStack {
                            Image(systemName: "sparkle")
                                .foregroundColor(.flintSpark)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Flint Plan")
                                    .font(.flintBody(15, weight: .semibold))
                                    .foregroundColor(.flintText)
                                Text("Get AI meal suggestions for your remaining macros")
                                    .font(.flintBody(12))
                                    .foregroundColor(.flintGrey)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.flintStone)
                        }
                        .padding()
                        .background(Color.flintMuted)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.flintBorder, lineWidth: 1))
                    }

                    // Today's meals
                    TodayMealsSection(meals: nutritionStore.todayMeals)

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
        return min(consumed / target, 1.5)
    }

    private var remaining: Double {
        max(0, target - consumed + burned * 0.5)
    }

    private var ringColor: Color {
        if consumed > target * 1.1 { return .flintDanger }
        return .flintSpark
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.flintSpark.opacity(0.15), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        LinearGradient(colors: [ringColor, .flintGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.3), radius: 12)
                    .animation(.spring(duration: 0.8, bounce: 0.15), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(remaining))")
                        .font(.flintDisplay(36))
                        .foregroundColor(.flintText)
                    Text("kcal remaining")
                        .font(.flintBody(12))
                        .foregroundColor(.flintGrey)
                }
            }
            .frame(width: 200, height: 200)

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

// MARK: - Health Snapshot

struct HealthSnapshotView: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Health Snapshot")
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintGrey)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                MiniHealthCard(value: "\(healthManager.steps)", label: "steps", color: .flintText)
                MiniHealthCard(value: "\(Int(healthManager.activeCalories))", label: "active", color: .flintSpark)
                MiniHealthCard(value: "\(Int(healthManager.exerciseMinutes))", label: "min", color: .flintSuccess)
                MiniHealthCard(value: healthManager.weight > 0 ? String(format: "%.1f", healthManager.weight) : "--", label: "kg", color: .flintText)
                MiniHealthCard(value: healthManager.restingHeartRate > 0 ? "\(Int(healthManager.restingHeartRate))" : "--", label: "RHR", color: .flintSpark)
                MiniHealthCard(value: healthManager.hrv > 0 ? "\(Int(healthManager.hrv))" : "--", label: "HRV", color: .flintSuccess)
                MiniHealthCard(value: healthManager.sleepHours > 0 ? String(format: "%.1f", healthManager.sleepHours) : "--", label: "sleep", color: .flintProtein)
                MiniHealthCard(value: healthManager.vo2Max > 0 ? String(format: "%.0f", healthManager.vo2Max) : "--", label: "VO2", color: .flintFat)
            }

            // Today's workouts
            if !healthManager.todayWorkouts.isEmpty {
                ForEach(healthManager.todayWorkouts) { workout in
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundColor(.flintSpark)
                            .font(.caption)
                        Text(workout.type)
                            .font(.flintBody(13, weight: .medium))
                            .foregroundColor(.flintText)
                        Spacer()
                        Text("\(Int(workout.duration / 60))min")
                            .font(.flintMono(12))
                            .foregroundColor(.flintGrey)
                        Text("\(Int(workout.calories))cal")
                            .font(.flintMono(12))
                            .foregroundColor(.flintGrey)
                    }
                    .padding(.vertical, 4)
                }

                // AI tip
                let ctx = healthManager.healthContext()
                let tip: String = {
                    if ctx.isPostWorkout { return "Great session. Extra protein in today's plan." }
                    if ctx.isLowSleep { return "Tough night. Eat well today — comfort food that fits your macros." }
                    if ctx.isGymDay { return "Gym day — extra protein in today's plan." }
                    return "Rest day. Stay consistent with your targets."
                }()

                Text("💡 \(tip)")
                    .font(.flintBody(12))
                    .foregroundColor(.flintGrey)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.flintMuted)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct MiniHealthCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.flintMono(14))
                .foregroundColor(color)
            Text(label)
                .font(.flintBody(10))
                .foregroundColor(.flintStone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.flintElevated)
        .cornerRadius(8)
    }
}

// MARK: - Streak + Level Bar

struct StreakLevelBar: View {
    let streak: Int
    let level: Int
    let xp: Int

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Text("🔥")
                Text("\(streak)-day streak")
                    .font(.flintBody(13, weight: .medium))
                    .foregroundColor(.flintText)
            }
            Spacer()
            HStack(spacing: 6) {
                Text("Lv.\(level)")
                    .font(.flintMono(13))
                    .foregroundColor(.flintGlow)
                Text("\(xp) XP")
                    .font(.flintMono(11))
                    .foregroundColor(.flintStone)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Challenge Mini Card

struct WeeklyChallengeMiniCard: View {
    let challenge: WeeklyChallengeData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("🎯 Weekly Flint")
                    .font(.flintBody(13, weight: .medium))
                    .foregroundColor(.flintGrey)
                Spacer()
                Text("\(challenge.current)/\(challenge.target)")
                    .font(.flintMono(13))
                    .foregroundColor(.flintText)
            }
            Text(challenge.title)
                .font(.flintBody(14, weight: .medium))
                .foregroundColor(.flintText)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.flintSpark.opacity(0.15))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.flintSpark)
                        .frame(width: geo.size.width * challenge.progress)
                        .animation(.spring(duration: 0.6), value: challenge.progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("+\(challenge.xpReward) XP")
                    .font(.flintMono(11))
                    .foregroundColor(.flintGlow)
                Spacer()
                let daysLeft = Calendar.current.dateComponents([.day], from: .now, to: challenge.endDate).day ?? 0
                Text("\(max(0, daysLeft))d left")
                    .font(.flintBody(11))
                    .foregroundColor(.flintStone)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(12)
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

    private var fillColor: Color {
        if current > target * 1.1 { return .flintDanger }
        if current >= target { return .flintSuccess }
        return color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 6, height: 6)
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
                        .fill(fillColor)
                        .frame(width: geo.size.width * progress)
                        .animation(.spring(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Today's Meals

struct TodayMealsSection: View {
    let meals: [MealData]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Meals")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)

            if meals.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.title)
                        .foregroundColor(.flintStone)
                    Text("No meals logged yet")
                        .font(.flintBody(14))
                        .foregroundColor(.flintGrey)
                    Text("Tap Log to get started")
                        .font(.flintBody(12))
                        .foregroundColor(.flintStone)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(meals) { meal in
                    MealDataRow(meal: meal)
                }
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct MealDataRow: View {
    let meal: MealData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(meal.name)
                    .font(.flintBody(14, weight: .medium))
                    .foregroundColor(.flintText)
                Spacer()
                Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.flintBody(11))
                    .foregroundColor(.flintStone)
            }

            let macros = meal.totalMacros
            HStack(spacing: 12) {
                Text("\(Int(macros.calories)) kcal")
                    .font(.flintMono(13))
                    .foregroundColor(.flintSpark)
                Text("P:\(Int(macros.protein))")
                    .font(.flintMono(11))
                    .foregroundColor(.flintProtein)
                Text("C:\(Int(macros.carbs))")
                    .font(.flintMono(11))
                    .foregroundColor(.flintCarbs)
                Text("F:\(Int(macros.fat))")
                    .font(.flintMono(11))
                    .foregroundColor(.flintFat)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Quick Actions

struct QuickActionsRow: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @State private var showQuickLog = false
    @State private var showWaterPicker = false
    @State private var selectedTab: ContentView.Tab?

    var body: some View {
        HStack(spacing: 12) {
            // Quick Log → navigate to Log tab
            Button {
                showQuickLog = true
            } label: {
                QuickActionLabel(title: "Quick Log", icon: "bolt.fill", color: .flintSpark)
            }
            .fullScreenCover(isPresented: $showQuickLog) {
                NavigationStack {
                    LogFoodView()
                        .environmentObject(nutritionStore)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("Close") { showQuickLog = false }
                                    .foregroundColor(.flintSpark)
                            }
                        }
                }
            }

            // Flint Scan → navigate to Log tab (same flow)
            Button {
                showQuickLog = true
            } label: {
                QuickActionLabel(title: "Flint Scan", icon: "camera.fill", color: .flintProtein)
            }

            // Water
            Button {
                showWaterPicker = true
            } label: {
                QuickActionLabel(title: "Water", icon: "drop.fill", color: .flintSuccess)
            }
            .sheet(isPresented: $showWaterPicker) {
                WaterLogSheet()
            }
        }
    }
}

struct QuickActionLabel: View {
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

// MARK: - Water Log Sheet

struct WaterLogSheet: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double = 250

    private let presets: [Double] = [150, 250, 330, 500, 750, 1000]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.flintSuccess)

                Text("\(Int(amount)) ml")
                    .font(.flintDisplay(32))
                    .foregroundColor(.flintText)

                Text("Today: \(Int(nutritionStore.waterIntake)) ml")
                    .font(.flintMono(14))
                    .foregroundColor(.flintGrey)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            amount = preset
                        } label: {
                            Text("\(Int(preset))ml")
                                .font(.flintBody(14, weight: amount == preset ? .semibold : .regular))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(amount == preset ? Color.flintSpark : Color.flintSurface)
                                .foregroundColor(amount == preset ? .white : .flintText)
                                .cornerRadius(10)
                        }
                    }
                }

                Button {
                    nutritionStore.addWater(amount)
                    if nutritionStore.waterIntake >= 3000 {
                        gamificationEngine.checkAndUnlockBadge(id: "water_champ")
                    }
                    dismiss()
                } label: {
                    Text("Log Water")
                        .font(.flintBody(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.flintSuccess)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.flintBlack)
            .navigationTitle("Log Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.flintSpark)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    DashboardView()
        .environmentObject(NutritionStore())
        .environmentObject(HealthManager())
        .environmentObject(GamificationEngine())
}
