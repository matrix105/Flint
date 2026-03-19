import SwiftUI
import SwiftData

struct MealHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var logs: [DailyLogData] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if logs.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 40))
                            .foregroundColor(.flintStone)
                        Text("No meal history yet")
                            .font(.flintBody(15, weight: .medium))
                            .foregroundColor(.flintGrey)
                        Text("Start logging meals to see your history here.")
                            .font(.flintBody(13))
                            .foregroundColor(.flintStone)
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(logs) { log in
                        HistoryDayCard(log: log)
                    }
                }
            }
            .padding()
        }
        .background(Color.flintBlack)
        .navigationTitle("Meal History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: loadHistory)
    }

    private func loadHistory() {
        let descriptor = FetchDescriptor<DailyLogData>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        logs = (try? modelContext.fetch(descriptor)) ?? []
    }
}

struct HistoryDayCard: View {
    let log: DailyLogData

    private var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(log.date) { return "Today" }
        if cal.isDateInYesterday(log.date) { return "Yesterday" }
        return log.date.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dayLabel)
                    .font(.flintBody(15, weight: .semibold))
                    .foregroundColor(.flintText)
                Spacer()
                Text("\(Int(log.totalMacros.calories)) kcal")
                    .font(.flintMono(14))
                    .foregroundColor(.flintSpark)
            }

            // Macro summary
            HStack(spacing: 12) {
                Text("P:\(Int(log.totalMacros.protein))g")
                    .font(.flintMono(12))
                    .foregroundColor(.flintProtein)
                Text("C:\(Int(log.totalMacros.carbs))g")
                    .font(.flintMono(12))
                    .foregroundColor(.flintCarbs)
                Text("F:\(Int(log.totalMacros.fat))g")
                    .font(.flintMono(12))
                    .foregroundColor(.flintFat)
                if log.waterIntake > 0 {
                    Spacer()
                    Text("💧 \(Int(log.waterIntake))ml")
                        .font(.flintMono(11))
                        .foregroundColor(.flintStone)
                }
            }

            // Meals
            ForEach(log.meals) { meal in
                HStack {
                    Text(meal.name)
                        .font(.flintBody(13))
                        .foregroundColor(.flintGrey)
                    Spacer()
                    Text(meal.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.flintBody(11))
                        .foregroundColor(.flintStone)
                    Text("\(Int(meal.totalMacros.calories))")
                        .font(.flintMono(12))
                        .foregroundColor(.flintText)
                }
            }
        }
        .padding()
        .background(Color.flintSurface)
        .cornerRadius(16)
    }
}
