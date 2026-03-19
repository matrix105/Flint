import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @EnvironmentObject var healthManager: HealthManager
    @State private var selectedSegment: ProgressSegment = .calendar

    enum ProgressSegment: String, CaseIterable {
        case calendar = "Calendar"
        case trends = "Trends"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Segment control
                    Picker("View", selection: $selectedSegment) {
                        ForEach(ProgressSegment.allCases, id: \.self) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedSegment == .calendar {
                        calendarView
                    } else {
                        trendsView
                    }
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Calendar View

    private var calendarView: some View {
        VStack(spacing: 16) {
            // Streak card
            StreakDetailCard(
                streak: gamificationEngine.streak,
                longestStreak: gamificationEngine.longestStreak
            )

            // Flint XP / Level
            FlintXPCard(xp: gamificationEngine.totalXP, level: gamificationEngine.level)

            // Weekly Flint challenge
            if let challenge = gamificationEngine.currentChallenge {
                NavigationLink(destination: WeeklyFlintDetailView()) {
                    WeeklyChallengeMiniCard(challenge: challenge)
                }
            }

            // Achievements
            NavigationLink(destination: AchievementsGalleryView()) {
                HStack {
                    Text("View All Badges")
                        .font(.flintBody(14, weight: .medium))
                        .foregroundColor(.flintSpark)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.flintSpark)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Trends View

    private var trendsView: some View {
        VStack(spacing: 16) {
            // Weight trend
            TrendCard(title: "Weight", value: healthManager.weight > 0 ? String(format: "%.1f kg", healthManager.weight) : "--")
            TrendCard(title: "Avg Daily Calories", value: "\(Int(nutritionStore.todayMacros.calories)) kcal")
            TrendCard(title: "Weekly Workouts", value: "\(healthManager.todayWorkouts.count) today")
            TrendCard(title: "Avg Sleep", value: healthManager.sleepHours > 0 ? String(format: "%.1f hrs", healthManager.sleepHours) : "--")

            // Weekly Summary
            WeeklySummaryCard(healthManager: healthManager, nutritionStore: nutritionStore)
        }
    }
}

// MARK: - Streak Detail Card

struct StreakDetailCard: View {
    let streak: Int
    let longestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Streak 🔥")
                    .font(.flintBody(13, weight: .medium))
                    .foregroundColor(.flintGrey)
                Spacer()
                Text("Best: \(longestStreak)")
                    .font(.flintMono(12))
                    .foregroundColor(.flintStone)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(streak)")
                    .font(.flintDisplay(36))
                    .foregroundColor(.flintSpark)
                Text("days")
                    .font(.flintBody(14))
                    .foregroundColor(.flintStone)
            }

            // Progress to next milestone
            let nextMilestone = nextStreakMilestone(streak)
            if nextMilestone > streak {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.flintSpark.opacity(0.15))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.flintSpark)
                            .frame(width: geo.size.width * Double(streak) / Double(nextMilestone))
                    }
                }
                .frame(height: 6)

                Text("\(nextMilestone - streak) more to next milestone")
                    .font(.flintBody(11))
                    .foregroundColor(.flintStone)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }

    private func nextStreakMilestone(_ current: Int) -> Int {
        let milestones = [3, 7, 14, 30, 60, 90, 180, 365]
        return milestones.first(where: { $0 > current }) ?? 365
    }
}

// MARK: - Flint XP Card

struct FlintXPCard: View {
    let xp: Int
    let level: Int

    private var levelProgress: Double {
        let currentLevelStart = (level - 1) * 500
        return min(1.0, Double(xp - currentLevelStart) / 500)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Flint Level \(level)")
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(xp) XP")
                    .font(.flintMono(14))
                    .foregroundColor(.flintGlow)
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

            Text("\(max(0, level * 500 - xp)) XP to Level \(level + 1)")
                .font(.flintBody(11))
                .foregroundColor(.flintStone)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

// MARK: - Trend Card

struct TrendCard: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.flintBody(14))
                .foregroundColor(.flintGrey)
            Spacer()
            Text(value)
                .font(.flintMono(14))
                .foregroundColor(.flintText)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(12)
    }
}

// MARK: - Weekly Summary

struct WeeklySummaryCard: View {
    @ObservedObject var healthManager: HealthManager
    @ObservedObject var nutritionStore: NutritionStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)

            SummaryRow(label: "Workout Minutes", value: "\(Int(healthManager.weeklyWorkoutMinutes))")
            SummaryRow(label: "Avg Resting HR", value: healthManager.restingHeartRate > 0 ? "\(Int(healthManager.restingHeartRate)) bpm" : "--")
            SummaryRow(label: "Current Weight", value: healthManager.weight > 0 ? String(format: "%.1f kg", healthManager.weight) : "--")
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.flintBody(13))
                .foregroundColor(.flintGrey)
            Spacer()
            Text(value)
                .font(.flintMono(13))
                .foregroundColor(.flintText)
        }
    }
}

#Preview {
    ProgressView()
        .environmentObject(NutritionStore())
        .environmentObject(GamificationEngine())
        .environmentObject(HealthManager())
}
