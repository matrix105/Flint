import SwiftUI

struct AchievementsGalleryView: View {
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @State private var selectedCategory: String = "all"

    private let categories = ["all", "getting_started", "streaks", "logging", "nutrition", "fitness", "health", "challenges", "special"]
    private let categoryLabels: [String: String] = [
        "all": "All",
        "getting_started": "Start",
        "streaks": "Streaks",
        "logging": "Logging",
        "nutrition": "Nutrition",
        "fitness": "Fitness",
        "health": "Health",
        "challenges": "Challenges",
        "special": "Special",
    ]

    private var filteredBadges: [FlintBadgeData] {
        if selectedCategory == "all" {
            return gamificationEngine.badges
        }
        return gamificationEngine.badges.filter { $0.category == selectedCategory }
    }

    private var unlockedCount: Int {
        gamificationEngine.badges.filter(\.isUnlocked).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Progress header
                VStack(spacing: 8) {
                    Text("\(unlockedCount) / \(gamificationEngine.badges.count)")
                        .font(.flintDisplay(28))
                        .foregroundColor(.flintText)
                    Text("badges unlocked")
                        .font(.flintBody(14))
                        .foregroundColor(.flintGrey)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.flintSpark.opacity(0.15))
                            RoundedRectangle(cornerRadius: 4)
                                .fill(LinearGradient(colors: [.flintSpark, .flintGlow], startPoint: .leading, endPoint: .trailing))
                                .frame(width: gamificationEngine.badges.isEmpty ? 0 : geo.size.width * Double(unlockedCount) / Double(gamificationEngine.badges.count))
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal)
                }
                .padding()

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(categoryLabels[cat] ?? cat.capitalized)
                                    .font(.flintBody(12, weight: selectedCategory == cat ? .semibold : .regular))
                                    .foregroundColor(selectedCategory == cat ? .white : .flintGrey)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color.flintSpark : Color.flintSurface)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Badge grid
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredBadges) { badge in
                        BadgeCell(badge: badge)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.flintBlack)
        .navigationTitle("Badges")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct BadgeCell: View {
    let badge: FlintBadgeData
    @State private var showDetail = false

    var body: some View {
        Button {
            if badge.isUnlocked { showDetail = true }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? Color.flintSpark.opacity(0.15) : Color.flintElevated)
                        .frame(width: 50, height: 50)

                    if badge.isUnlocked {
                        Image(systemName: badge.iconName)
                            .font(.title3)
                            .foregroundColor(.flintSpark)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.flintStone)
                    }
                }

                Text(badge.isUnlocked ? badge.name : "???")
                    .font(.flintBody(10))
                    .foregroundColor(badge.isUnlocked ? .flintText : .flintStone)
                    .lineLimit(1)

                if badge.isUnlocked {
                    Text("+\(badge.xpReward) XP")
                        .font(.flintBody(8))
                        .foregroundColor(.flintGlow)
                }
            }
            .opacity(badge.isUnlocked ? 1 : 0.4)
        }
        .sheet(isPresented: $showDetail) {
            BadgeDetailSheet(badge: badge)
                .presentationDetents([.medium])
        }
    }
}

struct BadgeDetailSheet: View {
    let badge: FlintBadgeData
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: badge.iconName)
                .font(.system(size: 50))
                .foregroundColor(.flintSpark)
                .padding()
                .background(Color.flintSpark.opacity(0.15))
                .clipShape(Circle())

            Text(badge.name)
                .font(.flintDisplay(22))
                .foregroundColor(.flintText)

            Text(badge.badgeDescription)
                .font(.flintBody(15))
                .foregroundColor(.flintGrey)
                .multilineTextAlignment(.center)

            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.flintGlow)
                Text("+\(badge.xpReward) Flint XP")
                    .font(.flintMono(14))
                    .foregroundColor(.flintGlow)
            }

            if let date = badge.unlockedDate {
                Text("Earned \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.flintBody(12))
                    .foregroundColor(.flintStone)
            }

            Spacer()

            Button("Close") { dismiss() }
                .font(.flintBody(15, weight: .medium))
                .foregroundColor(.flintSpark)
                .padding(.bottom, 20)
        }
        .padding()
        .background(Color.flintBlack)
    }
}
