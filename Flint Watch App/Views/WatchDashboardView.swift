import SwiftUI

struct WatchDashboardView: View {
    @State private var calories: Int = 0
    @State private var target: Int = 2000
    @State private var protein: Int = 0
    @State private var proteinTarget: Int = 150

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(calories) / Double(target), 1.0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // App header
                HStack {
                    Image(systemName: "sparkle")
                        .foregroundColor(.flintSpark)
                        .font(.caption)
                    Text("Flint")
                        .font(.headline)
                        .foregroundColor(.flintText)
                }

                // Calorie ring
                ZStack {
                    Circle()
                        .stroke(Color.flintSpark.opacity(0.2), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.flintSpark, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(target - calories)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.flintText)
                        Text("kcal left")
                            .font(.system(size: 10))
                            .foregroundColor(.flintGrey)
                    }
                }
                .frame(width: 100, height: 100)

                // Macro summary
                HStack(spacing: 12) {
                    WatchMacroLabel(label: "P", value: "\(protein)g", color: .flintProtein)
                    WatchMacroLabel(label: "C", value: "0g", color: .flintCarbs)
                    WatchMacroLabel(label: "F", value: "0g", color: .flintFat)
                }

                // Quick log button
                Button {
                    // Quick log action via WatchConnectivity
                } label: {
                    Label("Quick Log", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                }
                .tint(.flintSpark)
            }
            .padding(.horizontal)
        }
    }
}

struct WatchMacroLabel: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.flintStone)
        }
    }
}

// Extend Color for watchOS (shares same tokens)
extension Color {
    // watchOS uses the same Flint color tokens defined in FlintColors.swift
    // When building as a separate target, duplicate the color definitions or use a shared framework
}

#Preview {
    WatchDashboardView()
}
