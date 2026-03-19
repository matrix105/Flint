import SwiftUI

struct WeeklyFlintDetailView: View {
    @EnvironmentObject var gamificationEngine: GamificationEngine

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let challenge = gamificationEngine.currentChallenge {
                    // Active challenge
                    VStack(spacing: 16) {
                        Text("Weekly Flint")
                            .font(.flintDisplay(24))
                            .foregroundColor(.flintText)

                        Text(challenge.title)
                            .font(.flintBody(17, weight: .semibold))
                            .foregroundColor(.flintSpark)

                        Text(challenge.challengeDescription)
                            .font(.flintBody(14))
                            .foregroundColor(.flintGrey)
                            .multilineTextAlignment(.center)

                        // Progress ring
                        ZStack {
                            Circle()
                                .stroke(Color.flintSpark.opacity(0.15), lineWidth: 10)
                            Circle()
                                .trim(from: 0, to: challenge.progress)
                                .stroke(Color.flintSpark, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(duration: 0.6), value: challenge.progress)

                            VStack(spacing: 4) {
                                Text("\(challenge.current)/\(challenge.target)")
                                    .font(.flintDisplay(28))
                                    .foregroundColor(.flintText)
                                Text(challenge.isCompleted ? "Complete!" : "in progress")
                                    .font(.flintBody(12))
                                    .foregroundColor(challenge.isCompleted ? .flintSuccess : .flintGrey)
                            }
                        }
                        .frame(width: 150, height: 150)

                        // Reward
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.flintGlow)
                            Text("+\(challenge.xpReward) Flint XP")
                                .font(.flintMono(14))
                                .foregroundColor(.flintGlow)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.flintMuted)
                        .cornerRadius(20)

                        // Time remaining
                        if !challenge.isCompleted {
                            let daysLeft = Calendar.current.dateComponents([.day], from: .now, to: challenge.endDate).day ?? 0
                            Text("\(max(0, daysLeft)) days remaining")
                                .font(.flintBody(13))
                                .foregroundColor(.flintStone)
                        }
                    }
                    .padding()
                    .background(Color.flintSurface)
                    .cornerRadius(16)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.flintStone)
                        Text("No active challenge")
                            .font(.flintBody(15, weight: .medium))
                            .foregroundColor(.flintGrey)
                        Text("A new Weekly Flint will start on Monday.")
                            .font(.flintBody(13))
                            .foregroundColor(.flintStone)
                    }
                    .padding(40)
                }

                // Achievements preview
                AchievementsPreviewSection(badges: gamificationEngine.badges)
            }
            .padding()
        }
        .background(Color.flintBlack)
        .navigationTitle("Weekly Flint")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AchievementsPreviewSection: View {
    let badges: [FlintBadgeData]

    private var unlockedCount: Int {
        badges.filter(\.isUnlocked).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(unlockedCount)/\(badges.count)")
                    .font(.flintMono(13))
                    .foregroundColor(.flintGrey)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.flintSpark.opacity(0.15))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.flintSpark)
                        .frame(width: badges.isEmpty ? 0 : geo.size.width * Double(unlockedCount) / Double(badges.count))
                }
            }
            .frame(height: 6)

            // Badge grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(badges.prefix(10)) { badge in
                    VStack(spacing: 4) {
                        Image(systemName: badge.iconName)
                            .font(.title3)
                            .foregroundColor(badge.isUnlocked ? .flintSpark : .flintStone)
                        Text(badge.isUnlocked ? badge.name : "???")
                            .font(.flintBody(9))
                            .foregroundColor(badge.isUnlocked ? .flintGrey : .flintStone)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.flintElevated)
                    .cornerRadius(8)
                    .opacity(badge.isUnlocked ? 1 : 0.4)
                }
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}
