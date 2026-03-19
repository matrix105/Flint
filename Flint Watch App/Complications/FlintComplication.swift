import WidgetKit
import SwiftUI
import WatchConnectivity

// MARK: - Complication Timeline Provider

struct FlintTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlintEntry {
        FlintEntry(date: .now, calories: 1200, target: 2100, protein: 85, proteinTarget: 160, streak: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (FlintEntry) -> Void) {
        let entry = FlintEntry(date: .now, calories: 1200, target: 2100, protein: 85, proteinTarget: 160, streak: 5)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FlintEntry>) -> Void) {
        // Read latest data from app context
        let data = WatchConnectivityManager.shared.todayData
        let entry = FlintEntry(
            date: .now,
            calories: data?.calories ?? 0,
            target: data?.target ?? 2100,
            protein: data?.protein ?? 0,
            proteinTarget: data?.proteinTarget ?? 160,
            streak: data?.streak ?? 0
        )

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct FlintEntry: TimelineEntry {
    let date: Date
    let calories: Double
    let target: Double
    let protein: Double
    let proteinTarget: Double
    let streak: Int

    var remaining: Double { max(0, target - calories) }
    var progress: Double { target > 0 ? min(calories / target, 1.0) : 0 }
}

// MARK: - Complication Views

struct FlintComplicationCircular: View {
    let entry: FlintEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()

            ZStack {
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.flintSpark, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(entry.remaining))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("kcal")
                        .font(.system(size: 7))
                        .foregroundColor(.secondary)
                }
            }
            .padding(3)
        }
    }
}

struct FlintComplicationRectangular: View {
    let entry: FlintEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                    .foregroundColor(.flintSpark)
                Text("Flint")
                    .font(.system(size: 11, weight: .semibold))
                if entry.streak > 0 {
                    Spacer()
                    Text("🔥\(entry.streak)")
                        .font(.system(size: 10))
                }
            }

            Gauge(value: entry.progress) {
                Text("\(Int(entry.remaining)) kcal left")
                    .font(.system(size: 10))
            }
            .gaugeStyle(.linearCapacity)
            .tint(Color.flintSpark)

            HStack {
                Text("P: \(Int(entry.protein))/\(Int(entry.proteinTarget))g")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct FlintComplicationCorner: View {
    let entry: FlintEntry

    var body: some View {
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: 18))
                .foregroundColor(.flintSpark)
        }
        .widgetLabel {
            Gauge(value: entry.progress) {
                Text("\(Int(entry.remaining))")
            }
            .gaugeStyle(.linearCapacity)
            .tint(Color.flintSpark)
        }
    }
}

struct FlintComplicationInline: View {
    let entry: FlintEntry

    var body: some View {
        Text("⚡ \(Int(entry.remaining)) kcal left")
    }
}

// MARK: - Widget Definition

struct FlintComplicationWidget: Widget {
    let kind = "FlintComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlintTimelineProvider()) { entry in
            FlintComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Flint")
        .description("Track your calories and macros at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}

struct FlintComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FlintEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            FlintComplicationCircular(entry: entry)
        case .accessoryRectangular:
            FlintComplicationRectangular(entry: entry)
        case .accessoryCorner:
            FlintComplicationCorner(entry: entry)
        case .accessoryInline:
            FlintComplicationInline(entry: entry)
        default:
            FlintComplicationCircular(entry: entry)
        }
    }
}
