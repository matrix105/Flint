import SwiftUI

struct LogFoodView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var gamificationEngine: GamificationEngine
    @StateObject private var scanEngine = FlintScanEngine()
    @State private var mealDescription: String = ""
    @State private var selectedMealType: String = "Lunch"
    @State private var showLogSuccess = false

    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Meal type selector
                    MealTypeSelector(selected: $selectedMealType, types: mealTypes)

                    // Flint Scan - text input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Describe your meal")
                            .font(.flintBody(13, weight: .medium))
                            .foregroundColor(.flintGrey)

                        TextField("e.g. grilled chicken with rice and salad", text: $mealDescription, axis: .vertical)
                            .font(.flintBody(15))
                            .foregroundColor(.flintText)
                            .padding()
                            .background(Color.flintSurface)
                            .cornerRadius(12)
                            .lineLimit(3...6)
                    }

                    // Flint Scan button
                    Button {
                        Task {
                            _ = await scanEngine.analyzeMealDescription(mealDescription)
                        }
                    } label: {
                        HStack {
                            if scanEngine.isProcessing {
                                ProgressView()
                                    .tint(.flintBlack)
                            }
                            Text(scanEngine.isProcessing ? "Scanning..." : "Flint Scan")
                                .font(.flintBody(16, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.flintSpark)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(mealDescription.isEmpty || scanEngine.isProcessing)

                    // Photo scan option
                    Button {
                        // Camera capture — requires AVCaptureSession + Vision framework
                        // For now, use text input as primary scan method
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan with Camera")
                                .font(.flintBody(15, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.flintElevated)
                        .foregroundColor(.flintText)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.flintBorder, lineWidth: 1)
                        )
                    }

                    // Scan results
                    if let result = scanEngine.lastResult {
                        FlintScanResultView(result: result) {
                            logScanResult(result)
                        }
                    }

                    // Success confirmation
                    if showLogSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.flintSuccess)
                            Text("Meal logged!")
                                .font(.flintBody(14, weight: .medium))
                                .foregroundColor(.flintSuccess)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.large)
            .onReceive(NotificationCenter.default.publisher(for: .watchQuickLogReceived)) { notification in
                if let description = notification.userInfo?["description"] as? String {
                    handleWatchQuickLog(description)
                }
            }
        }
    }

    // MARK: - Log Scan Result

    private func logScanResult(_ result: FlintScanResult) {
        let foodItems = result.items.map { item in
            FoodItemData(
                name: item.name,
                calories: item.estimatedMacros.calories,
                protein: item.estimatedMacros.protein,
                carbs: item.estimatedMacros.carbs,
                fat: item.estimatedMacros.fat,
                servingSize: item.servingSize
            )
        }

        nutritionStore.logMeal(name: selectedMealType, items: foodItems)

        // Gamification
        gamificationEngine.evaluateAfterMealLog(
            todayMacros: nutritionStore.todayMacros,
            target: nutritionStore.target,
            mealCount: nutritionStore.todayMeals.count,
            streak: nutritionStore.streak
        )
        gamificationEngine.updateChallengeProgress()

        // Check time-based badges
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 7 { gamificationEngine.checkAndUnlockBadge(id: "early_bird") }
        if hour >= 0 && hour < 5 { gamificationEngine.checkAndUnlockBadge(id: "night_owl") }

        // First scan badge
        gamificationEngine.checkAndUnlockBadge(id: "first_scan")

        withAnimation { showLogSuccess = true }
        mealDescription = ""
        scanEngine.clearResult()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showLogSuccess = false }
        }
    }

    // MARK: - Watch Quick Log

    private func handleWatchQuickLog(_ description: String) {
        mealDescription = description
        Task {
            let result = await scanEngine.analyzeMealDescription(description)
            logScanResult(result)
        }
    }
}

// MARK: - Meal Type Selector

struct MealTypeSelector: View {
    @Binding var selected: String
    let types: [String]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(types, id: \.self) { type in
                Button {
                    selected = type
                } label: {
                    Text(type)
                        .font(.flintBody(13, weight: selected == type ? .semibold : .regular))
                        .foregroundColor(selected == type ? .white : .flintGrey)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selected == type ? Color.flintSpark : Color.flintSurface)
                        .cornerRadius(20)
                }
            }
        }
    }
}

// MARK: - Scan Result View

struct FlintScanResultView: View {
    let result: FlintScanResult
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundColor(.flintSpark)
                Text("Flint Scan Results")
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(Int(result.confidence * 100))% confidence")
                    .font(.flintMono(11))
                    .foregroundColor(.flintStone)
            }

            ForEach(result.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.flintBody(14, weight: .medium))
                            .foregroundColor(.flintText)
                        Text(item.servingSize)
                            .font(.flintBody(11))
                            .foregroundColor(.flintStone)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(item.estimatedMacros.calories)) kcal")
                            .font(.flintMono(13))
                            .foregroundColor(.flintSpark)
                        HStack(spacing: 6) {
                            Text("P:\(Int(item.estimatedMacros.protein))")
                                .foregroundColor(.flintProtein)
                            Text("C:\(Int(item.estimatedMacros.carbs))")
                                .foregroundColor(.flintCarbs)
                            Text("F:\(Int(item.estimatedMacros.fat))")
                                .foregroundColor(.flintFat)
                        }
                        .font(.flintMono(10))
                    }
                }
                .padding(.vertical, 4)
            }

            // Totals
            let totalMacros = result.items.reduce(into: MacroNutrients.zero) { r, item in
                r = r + item.estimatedMacros
            }
            Divider().background(Color.flintDivider)
            HStack {
                Text("Total")
                    .font(.flintBody(14, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(Int(totalMacros.calories)) kcal")
                    .font(.flintMono(14))
                    .foregroundColor(.flintSpark)
                Text("P:\(Int(totalMacros.protein)) C:\(Int(totalMacros.carbs)) F:\(Int(totalMacros.fat))")
                    .font(.flintMono(11))
                    .foregroundColor(.flintGrey)
            }

            // Note
            if !result.note.isEmpty {
                Text(result.note)
                    .font(.flintBody(12))
                    .foregroundColor(.flintGrey)
                    .padding(8)
                    .background(Color.flintMuted)
                    .cornerRadius(8)
            }

            // Log button
            Button(action: onLog) {
                Text("Log This Meal")
                    .font(.flintBody(15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.flintSpark)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(12)
    }
}

#Preview {
    LogFoodView()
        .environmentObject(NutritionStore())
        .environmentObject(GamificationEngine())
}
