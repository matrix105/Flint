import SwiftUI
import SwiftData

struct EditProfileView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var age: String = ""
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var goalWeight: String = ""
    @State private var sex: UserProfile.Sex = .male
    @State private var activityLevel: UserProfile.ActivityLevel = .moderatelyActive
    @State private var dietaryGoal: UserProfile.DietaryGoal = .maintain
    @State private var showSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Basic info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Basic Info")
                        .font(.flintBody(15, weight: .semibold))
                        .foregroundColor(.flintText)

                    ProfileTextField(label: "Name", text: $name)
                    ProfileTextField(label: "Age", text: $age, keyboard: .numberPad)
                }
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(16)

                // Body
                VStack(alignment: .leading, spacing: 12) {
                    Text("Body")
                        .font(.flintBody(15, weight: .semibold))
                        .foregroundColor(.flintText)

                    // Sex
                    HStack(spacing: 8) {
                        ForEach(UserProfile.Sex.allCases, id: \.self) { s in
                            Button {
                                sex = s
                            } label: {
                                Text(s.rawValue)
                                    .font(.flintBody(14, weight: sex == s ? .semibold : .regular))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(sex == s ? Color.flintSpark : Color.flintElevated)
                                    .foregroundColor(sex == s ? .white : .flintText)
                                    .cornerRadius(10)
                            }
                        }
                    }

                    ProfileTextField(label: "Height (cm)", text: $heightCm, keyboard: .decimalPad)
                    ProfileTextField(label: "Weight (kg)", text: $weightKg, keyboard: .decimalPad)
                    ProfileTextField(label: "Goal Weight (optional)", text: $goalWeight, keyboard: .decimalPad)
                }
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(16)

                // Goal
                VStack(alignment: .leading, spacing: 12) {
                    Text("Goal")
                        .font(.flintBody(15, weight: .semibold))
                        .foregroundColor(.flintText)

                    ForEach(UserProfile.DietaryGoal.allCases, id: \.self) { goal in
                        Button {
                            dietaryGoal = goal
                        } label: {
                            HStack {
                                Text(goal.rawValue)
                                    .font(.flintBody(14, weight: .medium))
                                    .foregroundColor(.flintText)
                                Spacer()
                                Image(systemName: dietaryGoal == goal ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(dietaryGoal == goal ? .flintSpark : .flintStone)
                            }
                            .padding(.vertical, 6)
                        }
                    }

                    Divider().background(Color.flintDivider)

                    Text("Activity Level")
                        .font(.flintBody(13, weight: .medium))
                        .foregroundColor(.flintGrey)

                    ForEach(UserProfile.ActivityLevel.allCases, id: \.self) { level in
                        Button {
                            activityLevel = level
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                    .font(.flintBody(14))
                                    .foregroundColor(.flintText)
                                Spacer()
                                Image(systemName: activityLevel == level ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(activityLevel == level ? .flintSpark : .flintStone)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color.flintSurface)
                .cornerRadius(16)

                // Save button
                Button(action: saveProfile) {
                    Text(showSaved ? "Saved!" : "Save & Recalculate Targets")
                        .font(.flintBody(16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(showSaved ? Color.flintSuccess : Color.flintSpark)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.flintBlack)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadCurrentProfile)
    }

    private func loadCurrentProfile() {
        let descriptor = FetchDescriptor<UserProfileData>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }
        name = profile.name
        age = "\(profile.age)"
        heightCm = String(format: "%.0f", profile.heightCm)
        weightKg = String(format: "%.1f", profile.weightKg)
        goalWeight = profile.goalWeight.map { String(format: "%.1f", $0) } ?? ""
        sex = profile.sex
        activityLevel = profile.activityLevel
        dietaryGoal = profile.dietaryGoal
    }

    private func saveProfile() {
        let descriptor = FetchDescriptor<UserProfileData>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        profile.name = name
        profile.age = Int(age) ?? profile.age
        profile.heightCm = Double(heightCm) ?? profile.heightCm
        profile.weightKg = Double(weightKg) ?? profile.weightKg
        profile.goalWeight = Double(goalWeight)
        profile.sex = sex
        profile.activityLevel = activityLevel
        profile.dietaryGoal = dietaryGoal

        try? modelContext.save()

        // Recalculate targets
        let newTarget = NutritionTarget.calculate(for: profile)
        nutritionStore.target = newTarget

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSaved = false }
        }
    }
}

struct ProfileTextField: View {
    let label: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
                .font(.flintBody(14))
                .foregroundColor(.flintGrey)
                .frame(width: 120, alignment: .leading)
            TextField("", text: $text)
                .font(.flintMono(14))
                .foregroundColor(.flintText)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboard)
        }
    }
}
