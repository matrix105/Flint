import SwiftUI
import WatchConnectivity

struct WatchDashboardView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var calories: Double = 0
    @State private var target: Double = 2100
    @State private var protein: Double = 0
    @State private var proteinTarget: Double = 160
    @State private var carbs: Double = 0
    @State private var carbsTarget: Double = 200
    @State private var fat: Double = 0
    @State private var fatTarget: Double = 65
    @State private var streak: Int = 0

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(calories / target, 1.0)
    }

    private var remaining: Double {
        max(0, target - calories)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // App header
                HStack(spacing: 4) {
                    Image(systemName: "sparkle")
                        .foregroundColor(.flintSpark)
                        .font(.caption2)
                    Text("Flint")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.flintText)
                    Spacer()
                    if streak > 0 {
                        Text("🔥\(streak)")
                            .font(.system(size: 11))
                    }
                }

                // Calorie ring
                ZStack {
                    Circle()
                        .stroke(Color.flintSpark.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [.flintSpark, .flintGlow], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.6), value: progress)

                    VStack(spacing: 0) {
                        Text("\(Int(remaining))")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.flintText)
                        Text("kcal left")
                            .font(.system(size: 9))
                            .foregroundColor(.flintGrey)
                    }
                }
                .frame(width: 100, height: 100)

                // Macro bars
                VStack(spacing: 4) {
                    WatchMacroBar(label: "P", current: protein, target: proteinTarget, color: .flintProtein)
                    WatchMacroBar(label: "C", current: carbs, target: carbsTarget, color: .flintCarbs)
                    WatchMacroBar(label: "F", current: fat, target: fatTarget, color: .flintFat)
                }

                Divider()

                // Last meal
                if let lastMeal = connectivity.lastMealName {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Last: \(connectivity.lastMealTime)")
                            .font(.system(size: 10))
                            .foregroundColor(.flintStone)
                        Text(lastMeal)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.flintText)
                            .lineLimit(1)
                        if let cal = connectivity.lastMealCalories {
                            Text("\(cal) kcal")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(.flintSpark)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Quick log
                NavigationLink(destination: WatchQuickLogView()) {
                    Label("Quick Log", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .tint(.flintSpark)
            }
            .padding(.horizontal)
        }
        .onReceive(connectivity.$todayData) { data in
            if let data {
                calories = data.calories
                target = data.target
                protein = data.protein
                proteinTarget = data.proteinTarget
                carbs = data.carbs
                carbsTarget = data.carbsTarget
                fat = data.fat
                fatTarget = data.fatTarget
                streak = data.streak
            }
        }
    }
}

struct WatchMacroBar: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(current / target, 1.0)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
                .frame(width: 12)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.2))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)

            Text("\(Int(current))g")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.flintGrey)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

// MARK: - Color extensions for watchOS

extension Color {
    static let flintSpark = Color(red: 233/255, green: 69/255, blue: 96/255)
    static let flintGlow = Color(red: 255/255, green: 107/255, blue: 129/255)
    static let flintText = Color(red: 240/255, green: 240/255, blue: 240/255)
    static let flintGrey = Color(red: 136/255, green: 136/255, blue: 160/255)
    static let flintStone = Color(red: 85/255, green: 85/255, blue: 102/255)
    static let flintProtein = Color(red: 59/255, green: 130/255, blue: 246/255)
    static let flintCarbs = Color(red: 245/255, green: 158/255, blue: 11/255)
    static let flintFat = Color(red: 168/255, green: 85/255, blue: 247/255)
    static let flintSurface = Color(red: 18/255, green: 18/255, blue: 26/255)
    static let flintElevated = Color(red: 26/255, green: 26/255, blue: 38/255)
    static let flintSuccess = Color(red: 34/255, green: 197/255, blue: 94/255)
}
