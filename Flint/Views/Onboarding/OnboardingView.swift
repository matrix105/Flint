import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var healthManager: HealthManager
    @EnvironmentObject var nutritionStore: NutritionStore
    @Environment(\.modelContext) private var modelContext
    @State private var step: OnboardingStep = .welcome
    @State private var name: String = ""
    @State private var age: String = "25"
    @State private var heightCm: String = "170"
    @State private var weightKg: String = "70"
    @State private var goalWeight: String = ""
    @State private var activityLevel: UserProfile.ActivityLevel = .moderatelyActive
    @State private var dietaryGoal: UserProfile.DietaryGoal = .maintain

    enum OnboardingStep: CaseIterable {
        case welcome, profile, body, goal, health, ready
    }

    var body: some View {
        ZStack {
            Color.flintBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                if step != .welcome {
                    OnboardingProgress(current: OnboardingStep.allCases.firstIndex(of: step) ?? 0, total: OnboardingStep.allCases.count)
                        .padding()
                }

                Spacer()

                Group {
                    switch step {
                    case .welcome: welcomeStep
                    case .profile: profileStep
                    case .body: bodyStep
                    case .goal: goalStep
                    case .health: healthStep
                    case .ready: readyStep
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                .animation(.easeInOut(duration: 0.3), value: step)

                Spacer()

                // Navigation buttons
                VStack(spacing: 12) {
                    Button(action: advanceStep) {
                        Text(step == .ready ? "Get Started" : "Continue")
                            .font(.flintBody(16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.flintSpark)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                    }

                    if step != .welcome && step != .ready {
                        Button("Back") {
                            withAnimation { goBack() }
                        }
                        .font(.flintBody(14))
                        .foregroundColor(.flintGrey)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkle")
                .font(.system(size: 60))
                .foregroundColor(.flintSpark)

            Text("Flint")
                .font(.flintDisplay(42))
                .foregroundColor(.flintText)

            Text("Track. Burn. Transform.")
                .font(.flintBody(18, weight: .medium))
                .foregroundColor(.flintGlow)

            Text("Your nutrition, powered by\non-device intelligence.")
                .font(.flintBody(15))
                .foregroundColor(.flintGrey)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }

    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(title: "About You", subtitle: "Let's personalise your experience.")

            OnboardingTextField(label: "Name", text: $name, placeholder: "Your name")
            OnboardingTextField(label: "Age", text: $age, placeholder: "25", keyboard: .numberPad)
        }
        .padding(.horizontal, 24)
    }

    private var bodyStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(title: "Your Body", subtitle: "We'll use this to calculate your targets.")

            OnboardingTextField(label: "Height (cm)", text: $heightCm, placeholder: "170", keyboard: .decimalPad)
            OnboardingTextField(label: "Weight (kg)", text: $weightKg, placeholder: "70", keyboard: .decimalPad)
            OnboardingTextField(label: "Goal Weight (optional)", text: $goalWeight, placeholder: "65", keyboard: .decimalPad)
        }
        .padding(.horizontal, 24)
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingHeader(title: "Your Goal", subtitle: "What are you working towards?")

            ForEach(UserProfile.DietaryGoal.allCases, id: \.self) { goal in
                OnboardingOptionRow(
                    title: goal.rawValue,
                    subtitle: goalDescription(goal),
                    isSelected: dietaryGoal == goal
                ) {
                    dietaryGoal = goal
                }
            }

            Divider().background(Color.flintDivider)

            Text("Activity Level")
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintGrey)

            ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                OnboardingOptionRow(
                    title: level.rawValue,
                    subtitle: nil,
                    isSelected: activityLevel == level
                ) {
                    activityLevel = level
                }
            }
        }
        .padding(.horizontal, 24)
    }

    private var healthStep: some View {
        VStack(spacing: 20) {
            OnboardingHeader(title: "Apple Health", subtitle: "Flint reads your workouts, sleep, and vitals to adapt your plan.")

            Image(systemName: "heart.fill")
                .font(.system(size: 50))
                .foregroundColor(.flintSpark)
                .padding()

            Text("All data stays on your device.\nFlint never uploads your health data.")
                .font(.flintBody(14))
                .foregroundColor(.flintGrey)
                .multilineTextAlignment(.center)

            Button {
                Task { try? await healthManager.requestAuthorization() }
            } label: {
                HStack {
                    Image(systemName: "heart.circle.fill")
                    Text("Connect Apple Health")
                }
                .font(.flintBody(15, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.flintElevated)
                .foregroundColor(.flintText)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.flintBorder, lineWidth: 1))
            }
            .padding(.horizontal, 24)

            if healthManager.isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.flintSuccess)
                    Text("Connected")
                        .foregroundColor(.flintSuccess)
                }
                .font(.flintBody(14))
            }
        }
    }

    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkle")
                .font(.system(size: 50))
                .foregroundColor(.flintSpark)

            Text("You're All Set")
                .font(.flintDisplay(28))
                .foregroundColor(.flintText)

            let target = computeTarget()
            VStack(spacing: 8) {
                Text("Your daily targets:")
                    .font(.flintBody(14))
                    .foregroundColor(.flintGrey)

                HStack(spacing: 16) {
                    TargetPill(value: "\(Int(target.calories))", label: "kcal", color: .flintSpark)
                    TargetPill(value: "\(Int(target.protein))g", label: "protein", color: .flintProtein)
                    TargetPill(value: "\(Int(target.carbs))g", label: "carbs", color: .flintCarbs)
                    TargetPill(value: "\(Int(target.fat))g", label: "fat", color: .flintFat)
                }
            }
            .padding()
            .background(Color.flintSurface)
            .cornerRadius(16)
            .padding(.horizontal, 24)

            Text("These adapt based on your activity and health data.")
                .font(.flintBody(13))
                .foregroundColor(.flintStone)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Navigation

    private func advanceStep() {
        withAnimation {
            switch step {
            case .welcome: step = .profile
            case .profile: step = .body
            case .body: step = .goal
            case .goal: step = .health
            case .health: step = .ready
            case .ready: completeOnboarding()
            }
        }
    }

    private func goBack() {
        switch step {
        case .profile: step = .welcome
        case .body: step = .profile
        case .goal: step = .body
        case .health: step = .goal
        case .ready: step = .health
        default: break
        }
    }

    private func completeOnboarding() {
        let profile = UserProfileData(
            name: name,
            age: Int(age) ?? 25,
            heightCm: Double(heightCm) ?? 170,
            weightKg: Double(weightKg) ?? 70,
            goalWeight: Double(goalWeight),
            activityLevel: activityLevel,
            dietaryGoal: dietaryGoal
        )
        profile.hasCompletedOnboarding = true
        modelContext.insert(profile)

        let target = NutritionTarget.calculate(for: profile)
        nutritionStore.target = target

        // Seed initial badges
        GamificationEngine.seedBadges(in: modelContext)

        try? modelContext.save()
        hasCompletedOnboarding = true
    }

    private func computeTarget() -> NutritionTarget {
        let profile = UserProfileData(
            name: name,
            age: Int(age) ?? 25,
            heightCm: Double(heightCm) ?? 170,
            weightKg: Double(weightKg) ?? 70,
            goalWeight: Double(goalWeight),
            activityLevel: activityLevel,
            dietaryGoal: dietaryGoal
        )
        return NutritionTarget.calculate(for: profile)
    }

    private func goalDescription(_ goal: UserProfile.DietaryGoal) -> String {
        switch goal {
        case .lose: return "500 kcal deficit for steady fat loss"
        case .maintain: return "Maintain your current weight"
        case .gain: return "300 kcal surplus for lean muscle gain"
        }
    }
}

// MARK: - Onboarding Components

struct OnboardingProgress: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<total, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index <= current ? Color.flintSpark : Color.flintElevated)
                    .frame(height: 3)
            }
        }
    }
}

struct OnboardingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.flintDisplay(28))
                .foregroundColor(.flintText)
            Text(subtitle)
                .font(.flintBody(15))
                .foregroundColor(.flintGrey)
        }
    }
}

struct OnboardingTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintGrey)
            TextField(placeholder, text: $text)
                .font(.flintBody(16))
                .foregroundColor(.flintText)
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(10)
                .keyboardType(keyboard)
        }
    }
}

struct OnboardingOptionRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.flintBody(15, weight: .medium))
                        .foregroundColor(.flintText)
                    if let subtitle {
                        Text(subtitle)
                            .font(.flintBody(12))
                            .foregroundColor(.flintStone)
                    }
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .flintSpark : .flintStone)
            }
            .padding(.vertical, 8)
        }
    }
}

struct TargetPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.flintMono(14))
                .foregroundColor(color)
            Text(label)
                .font(.flintBody(10))
                .foregroundColor(.flintStone)
        }
    }
}
