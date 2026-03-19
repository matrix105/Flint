import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var gamificationEngine: GamificationEngine

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Level card
                    LevelCard(
                        level: gamificationEngine.level,
                        xp: gamificationEngine.totalXP,
                        streak: gamificationEngine.streak
                    )

                    // Stat cards
                    StatCardsRow(gamification: gamificationEngine)

                    // Weekly Challenge
                    if let challenge = gamificationEngine.currentChallenge {
                        NavigationLink(destination: WeeklyFlintDetailView()) {
                            WeeklyChallengeMiniCard(challenge: challenge)
                        }
                    }

                    // Achievements preview
                    NavigationLink(destination: AchievementsGalleryView()) {
                        AchievementPreviewRow(badges: gamificationEngine.badges)
                    }

                    // Settings links
                    VStack(spacing: 0) {
                        NavigationLink(destination: SettingsView()) {
                            SettingsRow(icon: "gearshape.fill", label: "Settings", color: .flintGrey)
                        }
                        Divider().background(Color.flintDivider)
                        NavigationLink(destination: HealthSettingsView()) {
                            SettingsRow(icon: "heart.fill", label: "Apple Health", color: .flintSpark)
                        }
                        Divider().background(Color.flintDivider)
                        SettingsRow(icon: "lock.shield.fill", label: "Security", color: .flintFat)
                    }
                    .background(Color.flintSurface)
                    .cornerRadius(16)

                    // About
                    AboutSection()
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let level: Int
    let xp: Int
    let streak: Int

    private var levelTitle: String {
        switch level {
        case 1...2: return "Rookie"
        case 3...4: return "Starter"
        case 5...6: return "Tracker"
        case 7...8: return "Committed"
        case 9...10: return "Disciplined"
        case 11...12: return "Dedicated"
        case 13...14: return "Consistent"
        case 15...16: return "Advanced"
        case 17...18: return "Expert"
        case 19...20: return "Master"
        default: return "Legend"
        }
    }

    private var xpForNextLevel: Int {
        (level) * 500
    }

    private var levelProgress: Double {
        let currentLevelStart = (level - 1) * 500
        let progressInLevel = Double(xp - currentLevelStart)
        return min(1.0, progressInLevel / 500)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(spacing: 4) {
                    Text("Level \(level)")
                        .font(.flintDisplay(28))
                        .foregroundColor(.flintText)
                    Text(levelTitle)
                        .font(.flintBody(15, weight: .medium))
                        .foregroundColor(.flintGlow)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(xp) XP")
                        .font(.flintMono(16))
                        .foregroundColor(.flintSpark)
                    Text("🔥 \(streak) days")
                        .font(.flintBody(13))
                        .foregroundColor(.flintGrey)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.flintSpark.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(LinearGradient(colors: [.flintSpark, .flintGlow], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * levelProgress)
                }
            }
            .frame(height: 8)

            Text("\(xpForNextLevel - xp) XP to Level \(level + 1)")
                .font(.flintBody(11))
                .foregroundColor(.flintStone)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

// MARK: - Stat Cards

struct StatCardsRow: View {
    @ObservedObject var gamification: GamificationEngine

    var body: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(gamification.streak)", label: "Streak", emoji: "🔥")
            StatCard(value: "\(gamification.badges.filter(\.isUnlocked).count)", label: "Badges", emoji: "🏆")
            StatCard(value: "\(gamification.level)", label: "Level", emoji: "⚡")
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let emoji: String

    var body: some View {
        VStack(spacing: 4) {
            Text(emoji)
                .font(.title2)
            Text(value)
                .font(.flintDisplay(22))
                .foregroundColor(.flintText)
            Text(label)
                .font(.flintBody(11))
                .foregroundColor(.flintStone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.flintSurface)
        .cornerRadius(12)
    }
}

// MARK: - Achievement Preview

struct AchievementPreviewRow: View {
    let badges: [FlintBadgeData]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Badges")
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(badges.filter(\.isUnlocked).count)/\(badges.count)")
                    .font(.flintMono(12))
                    .foregroundColor(.flintGrey)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.flintStone)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(badges.filter(\.isUnlocked).prefix(6)) { badge in
                        VStack(spacing: 4) {
                            Image(systemName: badge.iconName)
                                .font(.title3)
                                .foregroundColor(.flintSpark)
                            Text(badge.name)
                                .font(.flintBody(9))
                                .foregroundColor(.flintGrey)
                                .lineLimit(1)
                        }
                        .frame(width: 56)
                        .padding(.vertical, 8)
                        .background(Color.flintElevated)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.flintBody(15))
                .foregroundColor(.flintText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.flintStone)
        }
        .padding()
    }
}

// MARK: - Health Settings

struct HealthSettingsView: View {
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Status")
                            .font(.flintBody(14))
                            .foregroundColor(.flintGrey)
                        Spacer()
                        if healthManager.isAuthorized {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.flintSuccess)
                                Text("Connected")
                                    .foregroundColor(.flintSuccess)
                            }
                            .font(.flintBody(14))
                        } else {
                            Button("Connect") {
                                Task { try? await healthManager.requestAuthorization() }
                            }
                            .font(.flintBody(14, weight: .medium))
                            .foregroundColor(.flintSpark)
                        }
                    }

                    Text("Flint reads your workouts, sleep, vitals, and activity to personalise your nutrition plan. All data stays on your device.")
                        .font(.flintBody(13))
                        .foregroundColor(.flintStone)
                }
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(Color.flintBlack)
        .navigationTitle("Apple Health")
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @State private var calorieTarget: String = ""
    @State private var proteinTarget: String = ""
    @State private var carbsTarget: String = ""
    @State private var fatTarget: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Daily targets
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Targets")
                        .font(.flintBody(15, weight: .semibold))
                        .foregroundColor(.flintText)

                    TargetEditRow(label: "Calories", value: $calorieTarget, unit: "kcal", color: .flintSpark)
                    TargetEditRow(label: "Protein", value: $proteinTarget, unit: "g", color: .flintProtein)
                    TargetEditRow(label: "Carbs", value: $carbsTarget, unit: "g", color: .flintCarbs)
                    TargetEditRow(label: "Fat", value: $fatTarget, unit: "g", color: .flintFat)

                    Button("Save Targets") {
                        nutritionStore.target = NutritionTarget(
                            calories: Double(calorieTarget) ?? nutritionStore.target.calories,
                            protein: Double(proteinTarget) ?? nutritionStore.target.protein,
                            carbs: Double(carbsTarget) ?? nutritionStore.target.carbs,
                            fat: Double(fatTarget) ?? nutritionStore.target.fat
                        )
                    }
                    .font(.flintBody(14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.flintSpark)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(16)

                // App info
                VStack(spacing: 4) {
                    Text("Flint v1.0")
                        .font(.flintBody(12))
                        .foregroundColor(.flintStone)
                    Text("Track. Burn. Transform.")
                        .font(.flintBody(12))
                        .foregroundColor(.flintSpark)
                }
                .padding(.top, 20)
            }
            .padding()
        }
        .background(Color.flintBlack)
        .navigationTitle("Settings")
        .onAppear {
            calorieTarget = "\(Int(nutritionStore.target.calories))"
            proteinTarget = "\(Int(nutritionStore.target.protein))"
            carbsTarget = "\(Int(nutritionStore.target.carbs))"
            fatTarget = "\(Int(nutritionStore.target.fat))"
        }
    }
}

struct TargetEditRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.flintBody(14))
                .foregroundColor(.flintText)
            Spacer()
            TextField("", text: $value)
                .font(.flintMono(14))
                .foregroundColor(.flintText)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .frame(width: 80)
            Text(unit)
                .font(.flintBody(12))
                .foregroundColor(.flintStone)
        }
    }
}

// MARK: - About

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Flint")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)
            Text("Privacy-first nutrition tracking powered by on-device AI. Your data never leaves your phone.")
                .font(.flintBody(13))
                .foregroundColor(.flintStone)
            Text("Track. Burn. Transform.")
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintSpark)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

#Preview {
    ProfileView()
        .environmentObject(NutritionStore())
        .environmentObject(HealthManager())
        .environmentObject(GamificationEngine())
}
