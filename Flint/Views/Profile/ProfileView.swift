import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var nutritionStore: NutritionStore
    @EnvironmentObject var healthManager: HealthManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile header
                    ProfileHeader()

                    // Nutrition targets
                    TargetsSection(target: nutritionStore.target)

                    // Health integration
                    HealthIntegrationSection(isAuthorized: healthManager.isAuthorized) {
                        Task {
                            try? await healthManager.requestAuthorization()
                        }
                    }

                    // About
                    AboutSection()
                }
                .padding()
            }
            .background(Color.flintBlack)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.flintGrey)
            Text("Your Profile")
                .font(.flintBody(17, weight: .semibold))
                .foregroundColor(.flintText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct TargetsSection: View {
    let target: NutritionTarget

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Targets")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)

            TargetRow(label: "Calories", value: "\(Int(target.calories)) kcal", color: .flintSpark)
            TargetRow(label: "Protein", value: "\(Int(target.protein))g", color: .flintProtein)
            TargetRow(label: "Carbs", value: "\(Int(target.carbs))g", color: .flintCarbs)
            TargetRow(label: "Fat", value: "\(Int(target.fat))g", color: .flintFat)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct TargetRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.flintBody(14))
                .foregroundColor(.flintText)
            Spacer()
            Text(value)
                .font(.flintMono(14))
                .foregroundColor(.flintGrey)
        }
    }
}

struct HealthIntegrationSection: View {
    let isAuthorized: Bool
    let onConnect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Health")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)

            if isAuthorized {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.flintSuccess)
                    Text("Connected")
                        .font(.flintBody(14))
                        .foregroundColor(.flintSuccess)
                }
            } else {
                Button(action: onConnect) {
                    Text("Connect Apple Health")
                        .font(.flintBody(14, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.flintElevated)
                        .foregroundColor(.flintText)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.flintBorder, lineWidth: 1)
                        )
                }
            }

            Text("Flint reads your workouts, sleep, and vitals to personalise your nutrition plan. All data stays on your device.")
                .font(.flintBody(12))
                .foregroundColor(.flintStone)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About Flint")
                .font(.flintBody(15, weight: .semibold))
                .foregroundColor(.flintText)
            Text("Privacy-first nutrition tracking powered by on-device AI. Your data never leaves your phone.")
                .font(.flintBody(13))
                .foregroundColor(.flintStone)
            Text("Track. Burn. Transform.")
                .font(.flintBody(13, weight: .medium))
                .foregroundColor(.flintSpark)
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}

#Preview {
    ProfileView()
        .environmentObject(NutritionStore())
        .environmentObject(HealthManager())
}
