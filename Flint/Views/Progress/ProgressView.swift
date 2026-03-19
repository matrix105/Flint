import SwiftUI

struct ProgressView: View {
    @EnvironmentObject var nutritionStore: NutritionStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Streak card
                    StreakCard(streak: nutritionStore.streak)

                    // Flint XP / Level
                    FlintXPCard(xp: nutritionStore.flintXP, level: nutritionStore.flintLevel)

                    // Weekly Flint challenge placeholder
                    WeeklyFlintCard()

                    // Weight trend placeholder
                    WeightTrendCard()
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streak: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Streak 🔥")
                    .font(.flintBody(13, weight: .medium))
                    .foregroundColor(.flintGrey)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(streak)")
                        .font(.flintDisplay(36))
                        .foregroundColor(.flintSpark)
                    Text("days")
                        .font(.flintBody(14))
                        .foregroundColor(.flintStone)
                }
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundColor(.flintSpark.opacity(0.3))
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

// MARK: - Flint XP Card

struct FlintXPCard: View {
    let xp: Int
    let level: Int

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
                        .fill(
                            LinearGradient(
                                colors: [.flintSpark, .flintGlow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.3) // placeholder progress
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

// MARK: - Weekly Flint Card

struct WeeklyFlintCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Weekly Flint")
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("3/7 days")
                    .font(.flintMono(13))
                    .foregroundColor(.flintGrey)
            }
            Text("Hit your protein target every day this week.")
                .font(.flintBody(13))
                .foregroundColor(.flintStone)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

// MARK: - Weight Trend

struct WeightTrendCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weight Trend")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)
            Text("Connect Apple Health to see your weight trend.")
                .font(.flintBody(13))
                .foregroundColor(.flintStone)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

#Preview {
    ProgressView()
        .environmentObject(NutritionStore())
}
