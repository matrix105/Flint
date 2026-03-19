import SwiftUI

struct LogFoodView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @StateObject private var scanEngine = FlintScanEngine()
    @State private var mealDescription: String = ""
    @State private var selectedMealType: String = "Lunch"

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
                        // Camera capture flow
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
                        FlintScanResultView(result: result)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.large)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkle")
                    .foregroundColor(.flintSpark)
                Text("Flint Scan Results")
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
            }

            ForEach(result.items) { item in
                HStack {
                    Text(item.name)
                        .font(.flintBody(14))
                        .foregroundColor(.flintText)
                    Spacer()
                    Text("\(Int(item.estimatedMacros.calories)) kcal")
                        .font(.flintMono(13))
                        .foregroundColor(.flintGrey)
                }
                .padding(.vertical, 4)
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
}
