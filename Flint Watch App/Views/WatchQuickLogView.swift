import SwiftUI
import WatchConnectivity

struct WatchQuickLogView: View {
    @EnvironmentObject var connectivity: WatchConnectivityManager
    @State private var showConfirmation = false
    @State private var loggedMeal: String = ""

    private let presets = [
        "Protein Shake",
        "Chicken & Rice",
        "Eggs & Toast",
        "Salad",
        "Oatmeal",
        "Greek Yogurt",
        "Steak & Veggies",
        "Sandwich",
    ]

    var body: some View {
        if showConfirmation {
            WatchLogConfirmation(mealName: loggedMeal)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    // Voice input
                    Button {
                        // Voice dictation handled by system
                    } label: {
                        Label("Speak Meal", systemImage: "mic.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .tint(.flintSpark)

                    Divider()

                    Text("Quick Add")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.flintGrey)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(presets, id: \.self) { preset in
                        Button {
                            sendQuickLog(preset)
                        } label: {
                            Text(preset)
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .tint(.flintText)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Quick Log")
        }
    }

    private func sendQuickLog(_ description: String) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(
            ["quickLog": description],
            replyHandler: nil
        )
        loggedMeal = description
        showConfirmation = true

        // Auto-dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showConfirmation = false
        }
    }
}

struct WatchLogConfirmation: View {
    let mealName: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.flintSuccess)

            Text("Logged!")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.flintText)

            Text(mealName)
                .font(.system(size: 13))
                .foregroundColor(.flintGrey)
                .multilineTextAlignment(.center)
        }
    }
}
