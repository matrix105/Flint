import Foundation
import NaturalLanguage

// MARK: - Flint Scan (On-Device AI Meal Analysis)

struct FlintScanResult: Identifiable {
    let id = UUID()
    let items: [ScannedFoodItem]
    let confidence: Double
    let source: ScanSource
    let note: String

    enum ScanSource: String {
        case text = "Text"
        case photo = "Photo"
    }
}

struct ScannedFoodItem: Identifiable {
    let id = UUID()
    let name: String
    let estimatedMacros: MacroNutrients
    let confidence: Double
    let servingSize: String
}

class FlintScanEngine: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published private(set) var lastResult: FlintScanResult?

    func clearResult() {
        lastResult = nil
    }

    // On-device food database for macro estimation
    private let foodDatabase: [String: (cal: Double, p: Double, c: Double, f: Double, serving: String)] = [
        // Proteins
        "chicken": (165, 31, 0, 3.6, "100g breast"),
        "beef": (250, 26, 0, 15, "100g"),
        "salmon": (208, 20, 0, 13, "100g fillet"),
        "tuna": (130, 29, 0, 0.6, "100g"),
        "egg": (78, 6, 0.6, 5, "1 large"),
        "eggs": (156, 12, 1.2, 10, "2 large"),
        "turkey": (135, 30, 0, 1, "100g breast"),
        "shrimp": (85, 20, 0, 0.5, "100g"),
        "tofu": (76, 8, 1.9, 4.8, "100g"),
        "steak": (271, 26, 0, 18, "150g"),
        "fish": (130, 26, 0, 2, "100g"),
        "yogurt": (100, 17, 6, 0.7, "170g greek"),
        "cottage cheese": (98, 11, 3.4, 4.3, "100g"),
        "protein shake": (130, 25, 5, 2, "1 scoop"),
        "whey": (120, 24, 3, 1, "1 scoop"),

        // Carbs
        "rice": (206, 4.3, 45, 0.4, "1 cup cooked"),
        "pasta": (220, 8, 43, 1.3, "1 cup cooked"),
        "bread": (79, 3, 15, 1, "1 slice"),
        "toast": (79, 3, 15, 1, "1 slice"),
        "oatmeal": (154, 5, 27, 2.6, "1 cup cooked"),
        "oats": (154, 5, 27, 2.6, "1 cup cooked"),
        "potato": (161, 4.3, 37, 0.2, "1 medium"),
        "sweet potato": (103, 2.3, 24, 0.1, "1 medium"),
        "banana": (105, 1.3, 27, 0.4, "1 medium"),
        "apple": (95, 0.5, 25, 0.3, "1 medium"),
        "quinoa": (222, 8, 39, 3.6, "1 cup cooked"),
        "tortilla": (120, 3, 20, 3, "1 medium"),
        "bagel": (245, 10, 48, 1.5, "1 whole"),
        "cereal": (150, 3, 33, 1, "1 cup"),
        "granola": (200, 5, 30, 8, "1/2 cup"),

        // Fats
        "avocado": (240, 3, 12, 22, "1 whole"),
        "nuts": (170, 5, 6, 15, "28g handful"),
        "almonds": (164, 6, 6, 14, "28g"),
        "peanut butter": (188, 8, 6, 16, "2 tbsp"),
        "olive oil": (119, 0, 0, 14, "1 tbsp"),
        "cheese": (113, 7, 0.4, 9, "28g"),
        "butter": (102, 0.1, 0, 12, "1 tbsp"),

        // Vegetables
        "salad": (20, 1.5, 3.5, 0.2, "1 cup mixed"),
        "broccoli": (55, 3.7, 11, 0.6, "1 cup"),
        "spinach": (7, 0.9, 1.1, 0.1, "1 cup raw"),
        "vegetables": (50, 2, 10, 0.5, "1 cup mixed"),
        "tomato": (22, 1.1, 4.8, 0.2, "1 medium"),
        "carrots": (52, 1.2, 12, 0.3, "1 cup"),
        "peppers": (30, 1, 7, 0.3, "1 medium"),

        // Common meals
        "sandwich": (350, 18, 35, 14, "1 whole"),
        "burger": (540, 34, 40, 27, "1 with bun"),
        "pizza": (285, 12, 36, 10, "1 slice"),
        "sushi": (200, 9, 38, 0.7, "6 pieces"),
        "wrap": (320, 20, 30, 12, "1 whole"),
        "soup": (150, 8, 18, 5, "1 bowl"),
        "curry": (300, 15, 25, 16, "1 serving"),
        "stir fry": (280, 20, 25, 10, "1 serving"),
        "tacos": (210, 9, 21, 10, "1 taco"),
        "burrito": (450, 22, 50, 18, "1 whole"),
        "bowl": (400, 25, 45, 12, "1 poke/buddha bowl"),
        "smoothie": (250, 10, 40, 5, "16oz"),
        "pancakes": (350, 8, 52, 12, "3 stack"),
        "french toast": (300, 10, 36, 14, "2 slices"),
        "omelette": (250, 18, 2, 18, "3-egg"),

        // Drinks
        "coffee": (5, 0.3, 0, 0, "1 cup black"),
        "latte": (130, 8, 13, 5, "12oz"),
        "cappuccino": (80, 5, 8, 3, "8oz"),
        "juice": (110, 1, 26, 0.3, "8oz"),
        "milk": (150, 8, 12, 8, "1 cup whole"),
        "protein bar": (220, 20, 25, 8, "1 bar"),

        // Snacks
        "chocolate": (150, 2, 17, 9, "28g"),
        "chips": (152, 2, 15, 10, "28g"),
        "crackers": (120, 2, 20, 4, "6 crackers"),
        "hummus": (70, 2, 6, 5, "2 tbsp"),
        "fruit": (80, 1, 20, 0.3, "1 medium piece"),

        // Additional proteins
        "tempeh": (195, 20, 8, 11, "100g"),
        "seitan": (120, 21, 4, 1, "100g"),
        "lamb": (250, 25, 0, 17, "100g"),
        "pork": (210, 27, 0, 11, "100g chop"),
        "cod": (82, 18, 0, 0.7, "100g"),
        "halibut": (110, 21, 0, 2.3, "100g"),
        "scallops": (100, 20, 3, 0.8, "100g"),
        "crab": (97, 19, 0, 1.5, "100g"),
        "bison": (143, 28, 0, 2.4, "100g"),
        "venison": (158, 30, 0, 3.2, "100g"),
        "duck": (201, 24, 0, 11, "100g"),
        "protein powder": (120, 24, 3, 1, "1 scoop"),

        // Grains & carbs
        "spaghetti": (220, 8, 43, 1.3, "1 cup cooked"),
        "penne": (220, 8, 43, 1.3, "1 cup cooked"),
        "noodles": (220, 8, 40, 3, "1 cup cooked"),
        "couscous": (176, 6, 36, 0.3, "1 cup cooked"),
        "barley": (193, 3.6, 44, 0.7, "1 cup cooked"),
        "millet": (207, 6, 41, 1.7, "1 cup cooked"),
        "farro": (200, 7, 37, 1.5, "1 cup cooked"),
        "brown rice": (216, 5, 45, 1.8, "1 cup cooked"),
        "white rice": (206, 4.3, 45, 0.4, "1 cup cooked"),
        "jasmine rice": (205, 4.2, 45, 0.4, "1 cup cooked"),
        "corn": (132, 5, 29, 1.8, "1 ear"),
        "pita": (165, 5.5, 33, 0.7, "1 whole"),
        "naan": (260, 9, 45, 5, "1 piece"),
        "croissant": (230, 5, 26, 12, "1 piece"),
        "muffin": (340, 6, 50, 13, "1 medium"),
        "waffle": (220, 6, 25, 11, "1 piece"),

        // Vegetables
        "cauliflower": (27, 2, 5, 0.3, "1 cup"),
        "kale": (33, 2.9, 6, 0.6, "1 cup"),
        "zucchini": (17, 1.2, 3.1, 0.3, "1 cup"),
        "mushrooms": (22, 3, 3.3, 0.3, "1 cup"),
        "asparagus": (27, 3, 5, 0.2, "6 spears"),
        "green beans": (31, 1.8, 7, 0.1, "1 cup"),
        "brussels sprouts": (56, 4, 11, 0.8, "1 cup"),
        "eggplant": (35, 1, 9, 0.2, "1 cup"),
        "cabbage": (22, 1, 5, 0.1, "1 cup"),
        "celery": (14, 0.7, 3, 0.2, "2 stalks"),
        "cucumber": (16, 0.7, 3.6, 0.1, "1 cup"),
        "onion": (44, 1.2, 10, 0.1, "1 medium"),
        "garlic": (4, 0.2, 1, 0, "1 clove"),
        "peas": (67, 5, 12, 0.3, "1/2 cup"),
        "edamame": (120, 11, 9, 5, "1/2 cup"),
        "beets": (58, 2.2, 13, 0.2, "1 medium"),

        // Fruits
        "orange": (62, 1.2, 15, 0.2, "1 medium"),
        "strawberries": (49, 1, 12, 0.5, "1 cup"),
        "blueberries": (85, 1.1, 21, 0.5, "1 cup"),
        "raspberries": (64, 1.5, 15, 0.8, "1 cup"),
        "mango": (99, 1.4, 25, 0.6, "1 cup"),
        "pineapple": (82, 0.9, 22, 0.2, "1 cup"),
        "grapes": (62, 0.6, 16, 0.3, "1 cup"),
        "watermelon": (46, 0.9, 12, 0.2, "1 cup"),
        "peach": (59, 1.4, 14, 0.4, "1 medium"),
        "pear": (101, 0.7, 27, 0.2, "1 medium"),
        "berries": (60, 1, 14, 0.5, "1 cup mixed"),
        "dates": (66, 0.4, 18, 0, "2 dates"),

        // Dairy & alternatives
        "cream cheese": (50, 1, 0.8, 5, "1 tbsp"),
        "mozzarella": (85, 6, 0.7, 6, "28g"),
        "parmesan": (110, 10, 0.9, 7.3, "28g"),
        "feta": (75, 4, 1.2, 6, "28g"),
        "almond milk": (30, 1, 1, 2.5, "1 cup"),
        "oat milk": (120, 3, 16, 5, "1 cup"),
        "soy milk": (80, 7, 4, 4, "1 cup"),

        // Sauces & condiments
        "ketchup": (20, 0, 5, 0, "1 tbsp"),
        "mustard": (3, 0.2, 0.3, 0.2, "1 tsp"),
        "mayo": (94, 0.1, 0, 10, "1 tbsp"),
        "soy sauce": (8, 1, 1, 0, "1 tbsp"),
        "salsa": (10, 0.5, 2, 0, "2 tbsp"),
        "ranch": (73, 0.4, 1, 8, "1 tbsp"),
        "hot sauce": (0, 0, 0, 0, "1 tsp"),
        "bbq sauce": (30, 0, 7, 0, "1 tbsp"),

        // Restaurant / international
        "tikka masala": (350, 20, 15, 22, "1 serving"),
        "pad thai": (400, 15, 50, 16, "1 serving"),
        "fried rice": (350, 10, 50, 12, "1 cup"),
        "ramen": (450, 18, 55, 18, "1 bowl"),
        "pho": (350, 25, 40, 8, "1 bowl"),
        "falafel": (330, 13, 32, 18, "4 pieces"),
        "gyros": (420, 25, 35, 20, "1 wrap"),
        "bibimbap": (500, 25, 60, 16, "1 bowl"),
        "dumplings": (250, 10, 28, 10, "6 pieces"),
        "spring rolls": (130, 3, 16, 6, "2 rolls"),
        "quesadilla": (350, 15, 30, 18, "1 whole"),
        "nachos": (400, 12, 35, 22, "1 plate"),
        "mac and cheese": (380, 14, 44, 16, "1 cup"),
        "lasagna": (380, 22, 35, 16, "1 serving"),
        "risotto": (350, 8, 50, 12, "1 cup"),
        "fish and chips": (600, 25, 55, 30, "1 serving"),
        "shawarma": (400, 28, 30, 18, "1 wrap"),
        "kebab": (280, 22, 8, 18, "1 skewer"),
    ]

    /// Analyze a text description of a meal using on-device NLP + food database
    func analyzeMealDescription(_ text: String) async -> FlintScanResult {
        await MainActor.run { isProcessing = true }
        defer { Task { @MainActor in isProcessing = false } }

        let lowered = text.lowercased()
        var items: [ScannedFoodItem] = []
        var matchedRanges: [Range<String.Index>] = []

        // Multi-word matches first (e.g. "peanut butter", "sweet potato")
        let sortedKeys = foodDatabase.keys.sorted { $0.count > $1.count }

        for key in sortedKeys {
            if let range = lowered.range(of: key) {
                // Avoid overlapping matches
                let overlaps = matchedRanges.contains { $0.overlaps(range) }
                if !overlaps {
                    matchedRanges.append(range)
                    let data = foodDatabase[key]!

                    // Detect quantity modifiers
                    let multiplier = detectQuantityMultiplier(text: lowered, beforeRange: range)

                    let macros = MacroNutrients(
                        calories: data.cal * multiplier,
                        protein: data.p * multiplier,
                        carbs: data.c * multiplier,
                        fat: data.f * multiplier
                    )

                    items.append(ScannedFoodItem(
                        name: key.capitalized,
                        estimatedMacros: macros,
                        confidence: 0.85,
                        servingSize: multiplier > 1 ? "\(Int(multiplier))x \(data.serving)" : data.serving
                    ))
                }
            }
        }

        // Also use NLP to find potential food nouns not in database
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            if tag == .noun {
                let word = String(text[range]).lowercased()
                let alreadyMatched = items.contains { $0.name.lowercased() == word }
                if !alreadyMatched && word.count > 2 && foodDatabase[word] == nil {
                    // Unknown food item — flag with low confidence
                    items.append(ScannedFoodItem(
                        name: word.capitalized,
                        estimatedMacros: MacroNutrients(calories: 100, protein: 5, carbs: 10, fat: 5),
                        confidence: 0.3,
                        servingSize: "estimated"
                    ))
                }
            }
            return true
        }

        let totalConfidence = items.isEmpty ? 0 : items.reduce(0.0) { $0 + $1.confidence } / Double(items.count)
        let note = generateScanNote(items: items)

        let result = FlintScanResult(items: items, confidence: totalConfidence, source: .text, note: note)
        await MainActor.run { lastResult = result }
        return result
    }

    private func detectQuantityMultiplier(text: String, beforeRange: Range<String.Index>) -> Double {
        let prefix = String(text[text.startIndex..<beforeRange.lowerBound])
        let words = prefix.split(separator: " ")
        guard let lastWord = words.last else { return 1 }
        let word = String(lastWord)

        // Number words
        let numberWords: [String: Double] = [
            "two": 2, "three": 3, "four": 4, "five": 5,
            "double": 2, "triple": 3, "half": 0.5,
        ]
        if let num = numberWords[word] { return num }
        if let num = Double(word) { return num }
        return 1
    }

    private func generateScanNote(items: [ScannedFoodItem]) -> String {
        let lowConfidence = items.filter { $0.confidence < 0.5 }
        if items.isEmpty {
            return "Couldn't identify any foods. Try describing specific items."
        } else if !lowConfidence.isEmpty {
            let names = lowConfidence.map(\.name).joined(separator: ", ")
            return "Some items estimated: \(names). Tap to adjust."
        } else {
            let total = items.reduce(0.0) { $0 + $1.estimatedMacros.calories }
            return "\(Int(total)) kcal total · P:\(Int(items.reduce(0.0) { $0 + $1.estimatedMacros.protein })) C:\(Int(items.reduce(0.0) { $0 + $1.estimatedMacros.carbs })) F:\(Int(items.reduce(0.0) { $0 + $1.estimatedMacros.fat }))"
        }
    }
}

// MARK: - Flint Plan Generator

class FlintPlanEngine: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var currentPlan: MealPlan?

    struct MealPlan: Identifiable {
        let id = UUID()
        let meals: [PlannedMeal]
        let totalMacros: MacroNutrients
        let note: String
        let generatedAt: Date
    }

    struct PlannedMeal: Identifiable {
        let id = UUID()
        let name: String
        let mealType: String
        let description: String
        let macros: MacroNutrients
        let items: [String]
    }

    // On-device meal templates
    private let mealTemplates: [(name: String, type: String, items: [String], macros: MacroNutrients)] = [
        // Breakfasts
        ("Greek Yogurt Bowl", "Breakfast", ["Greek yogurt", "Granola", "Banana", "Honey"],
         MacroNutrients(calories: 380, protein: 25, carbs: 50, fat: 8)),
        ("Protein Oats", "Breakfast", ["Oatmeal", "Whey protein", "Banana", "Peanut butter"],
         MacroNutrients(calories: 450, protein: 35, carbs: 55, fat: 12)),
        ("Egg & Toast", "Breakfast", ["3 eggs scrambled", "2 toast", "Avocado"],
         MacroNutrients(calories: 480, protein: 24, carbs: 32, fat: 28)),
        ("Smoothie Bowl", "Breakfast", ["Protein shake", "Banana", "Spinach", "Almonds"],
         MacroNutrients(calories: 350, protein: 30, carbs: 38, fat: 10)),

        // Lunches
        ("Chicken & Rice", "Lunch", ["Grilled chicken breast", "Brown rice", "Mixed vegetables"],
         MacroNutrients(calories: 520, protein: 42, carbs: 55, fat: 10)),
        ("Tuna Salad Wrap", "Lunch", ["Tuna", "Tortilla wrap", "Mixed greens", "Avocado"],
         MacroNutrients(calories: 430, protein: 35, carbs: 30, fat: 18)),
        ("Turkey Bowl", "Lunch", ["Ground turkey", "Quinoa", "Black beans", "Peppers"],
         MacroNutrients(calories: 490, protein: 38, carbs: 48, fat: 14)),
        ("Salmon Poke Bowl", "Lunch", ["Salmon", "Sushi rice", "Edamame", "Avocado"],
         MacroNutrients(calories: 510, protein: 32, carbs: 50, fat: 18)),

        // Dinners
        ("Steak & Sweet Potato", "Dinner", ["Sirloin steak", "Sweet potato", "Broccoli"],
         MacroNutrients(calories: 550, protein: 40, carbs: 42, fat: 20)),
        ("Grilled Salmon", "Dinner", ["Salmon fillet", "Asparagus", "Quinoa"],
         MacroNutrients(calories: 480, protein: 38, carbs: 35, fat: 18)),
        ("Chicken Stir Fry", "Dinner", ["Chicken thigh", "Mixed vegetables", "Rice noodles", "Soy sauce"],
         MacroNutrients(calories: 460, protein: 32, carbs: 45, fat: 14)),
        ("Lean Burger", "Dinner", ["Lean beef patty", "Whole wheat bun", "Side salad"],
         MacroNutrients(calories: 520, protein: 36, carbs: 38, fat: 22)),

        // Snacks
        ("Protein Bar & Fruit", "Snack", ["Protein bar", "Apple"],
         MacroNutrients(calories: 315, protein: 22, carbs: 45, fat: 8)),
        ("Nuts & Yogurt", "Snack", ["Greek yogurt", "Mixed nuts"],
         MacroNutrients(calories: 270, protein: 20, carbs: 12, fat: 16)),
        ("Cottage Cheese & Berries", "Snack", ["Cottage cheese", "Mixed berries"],
         MacroNutrients(calories: 180, protein: 15, carbs: 18, fat: 5)),
    ]

    /// Generate a personalized daily meal plan
    func generatePlan(target: NutritionTarget, consumed: MacroNutrients, healthContext: HealthContext?) async -> MealPlan {
        await MainActor.run { isGenerating = true }
        defer { Task { @MainActor in isGenerating = false } }

        let remaining = MacroNutrients(
            calories: max(0, target.calories - consumed.calories),
            protein: max(0, target.protein - consumed.protein),
            carbs: max(0, target.carbs - consumed.carbs),
            fat: max(0, target.fat - consumed.fat)
        )

        var selectedMeals: [PlannedMeal] = []
        var budgetLeft = remaining

        // Determine which meal types to suggest based on time of day
        let hour = Calendar.current.component(.hour, from: .now)
        let neededTypes: [String]
        if hour < 10 {
            neededTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]
        } else if hour < 14 {
            neededTypes = ["Lunch", "Dinner", "Snack"]
        } else if hour < 18 {
            neededTypes = ["Dinner", "Snack"]
        } else {
            neededTypes = ["Snack"]
        }

        for mealType in neededTypes {
            let candidates = mealTemplates.filter { $0.type == mealType }
            guard !candidates.isEmpty else { continue }

            // Score candidates by how well they fit remaining budget
            let scored = candidates.map { template in
                let calFit = 1.0 - min(1.0, abs(template.macros.calories - budgetLeft.calories / Double(neededTypes.count)) / target.calories)
                let proFit = 1.0 - min(1.0, abs(template.macros.protein - budgetLeft.protein / Double(neededTypes.count)) / max(1, target.protein))
                return (template: template, score: calFit * 0.4 + proFit * 0.6)
            }.sorted { $0.score > $1.score }

            if let best = scored.first?.template {
                // Apply health-aware adjustments
                var description = best.name
                var macros = best.macros

                if let ctx = healthContext {
                    if ctx.isPostWorkout && mealType != "Snack" {
                        description += " (post-workout: extra protein)"
                        macros = MacroNutrients(
                            calories: macros.calories + 80,
                            protein: macros.protein + 15,
                            carbs: macros.carbs + 10,
                            fat: macros.fat
                        )
                    }
                    if ctx.isLowSleep {
                        description += " (comfort-friendly)"
                    }
                }

                let planned = PlannedMeal(
                    name: best.name,
                    mealType: best.type,
                    description: description,
                    macros: macros,
                    items: best.items
                )
                selectedMeals.append(planned)

                budgetLeft = MacroNutrients(
                    calories: max(0, budgetLeft.calories - macros.calories),
                    protein: max(0, budgetLeft.protein - macros.protein),
                    carbs: max(0, budgetLeft.carbs - macros.carbs),
                    fat: max(0, budgetLeft.fat - macros.fat)
                )
            }
        }

        let totalPlanned = selectedMeals.reduce(into: MacroNutrients.zero) { $0 = $0 + $1.macros }

        // Generate contextual note
        let note: String
        if let ctx = healthContext {
            if ctx.isPostWorkout {
                note = "Great session. Your plan's updated with extra protein."
            } else if ctx.isLowSleep {
                note = "Tough night. Today's plan has comfort food that still hits your macros."
            } else if ctx.isGymDay {
                note = "Gym day — extra protein in today's plan."
            } else {
                note = "Your plan is optimised for your remaining targets."
            }
        } else {
            note = "Your plan is optimised for your remaining targets."
        }

        let plan = MealPlan(meals: selectedMeals, totalMacros: totalPlanned, note: note, generatedAt: .now)
        await MainActor.run { currentPlan = plan }
        return plan
    }

    /// Generate meal variations for a specific meal
    func generateVariations(for mealType: String, target: MacroNutrients, count: Int = 3) -> [PlannedMeal] {
        let candidates = mealTemplates.filter { $0.type == mealType }
        let sorted = candidates.sorted {
            abs($0.macros.calories - target.calories) < abs($1.macros.calories - target.calories)
        }

        return Array(sorted.prefix(count)).map { template in
            PlannedMeal(
                name: template.name,
                mealType: template.type,
                description: template.name,
                macros: template.macros,
                items: template.items
            )
        }
    }
}

