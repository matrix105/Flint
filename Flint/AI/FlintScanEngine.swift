import Foundation
import NaturalLanguage

// MARK: - Flint Scan (On-Device AI Meal Analysis)

struct FlintScanResult: Identifiable {
    let id = UUID()
    let items: [ScannedFoodItem]
    let confidence: Double
    let source: ScanSource

    enum ScanSource {
        case text
        case photo
    }
}

struct ScannedFoodItem {
    let name: String
    let estimatedMacros: MacroNutrients
    let confidence: Double
}

class FlintScanEngine: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var lastResult: FlintScanResult?

    /// Analyze a text description of a meal using on-device NLP
    func analyzeMealDescription(_ text: String) async -> FlintScanResult {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        // On-device NLP tokenization and entity recognition
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        var items: [ScannedFoodItem] = []
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range])
                // Placeholder: in production, this would use a Core ML model
                let item = ScannedFoodItem(
                    name: word,
                    estimatedMacros: MacroNutrients(calories: 0, protein: 0, carbs: 0, fat: 0),
                    confidence: 0.5
                )
                items.append(item)
            }
            return true
        }

        let result = FlintScanResult(items: items, confidence: 0.7, source: .text)
        await MainActor.run { lastResult = result }
        return result
    }
}

// MARK: - Flint Plan Generator

class FlintPlanEngine: ObservableObject {
    @Published var isGenerating: Bool = false

    struct MealPlan: Identifiable {
        let id = UUID()
        let meals: [PlannedMeal]
        let totalMacros: MacroNutrients
        let note: String
    }

    struct PlannedMeal: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let macros: MacroNutrients
        let items: [String]
    }

    /// Generate a personalized daily meal plan based on targets and health data
    func generatePlan(target: NutritionTarget, consumed: MacroNutrients, activityLevel: String) async -> MealPlan {
        await MainActor.run { isGenerating = true }
        defer { Task { @MainActor in isGenerating = false } }

        let remaining = MacroNutrients(
            calories: max(0, target.calories - consumed.calories),
            protein: max(0, target.protein - consumed.protein),
            carbs: max(0, target.carbs - consumed.carbs),
            fat: max(0, target.fat - consumed.fat)
        )

        // Placeholder plan generation — in production, uses Core ML model
        let plan = MealPlan(
            meals: [],
            totalMacros: remaining,
            note: "Your plan adapts to your activity and remaining targets."
        )

        return plan
    }
}
