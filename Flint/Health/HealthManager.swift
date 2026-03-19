import Foundation
import HealthKit
import Combine

@MainActor
class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()

    // Activity
    @Published var activeCalories: Double = 0
    @Published var restingCalories: Double = 0
    @Published var steps: Int = 0
    @Published var exerciseMinutes: Double = 0
    @Published var standHours: Int = 0

    // Body
    @Published var weight: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var height: Double = 0
    @Published var leanBodyMass: Double = 0
    @Published var bmi: Double = 0

    // Vitals
    @Published var heartRate: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var hrv: Double = 0
    @Published var vo2Max: Double = 0
    @Published var bloodOxygen: Double = 0
    @Published var respiratoryRate: Double = 0

    // Sleep
    @Published var sleepHours: Double = 0
    @Published var sleepStages: SleepSummary = .empty

    // Workouts
    @Published var latestWorkout: WorkoutSummary?
    @Published var todayWorkouts: [WorkoutSummary] = []
    @Published var weeklyWorkoutMinutes: Double = 0

    // State
    @Published var isAuthorized: Bool = false

    struct SleepSummary: Equatable {
        var total: Double
        var rem: Double
        var deep: Double
        var core: Double
        var awake: Double
        static let empty = SleepSummary(total: 0, rem: 0, deep: 0, core: 0, awake: 0)
    }

    struct WorkoutSummary: Identifiable, Equatable {
        let id: UUID
        let type: String
        let duration: TimeInterval
        let calories: Double
        let startDate: Date
        let endDate: Date
        let heartRateAvg: Double?
    }

    // MARK: - 21 HealthKit Read Types

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()

        let quantityTypes: [HKQuantityTypeIdentifier] = [
            // Activity (5)
            .activeEnergyBurned,
            .basalEnergyBurned,
            .stepCount,
            .appleExerciseTime,
            .appleStandTime,
            // Body (5)
            .bodyMass,
            .bodyFatPercentage,
            .height,
            .leanBodyMass,
            .bodyMassIndex,
            // Vitals (6)
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .vo2Max,
            .oxygenSaturation,
            .respiratoryRate,
            // Nutrition (3)
            .dietaryWater,
            .dietaryEnergyConsumed,
            .dietaryProtein,
        ]

        for identifier in quantityTypes {
            if let type = HKObjectType.quantityType(forIdentifier: identifier) {
                types.insert(type)
            }
        }

        // Sleep (1)
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        // Workouts (1)
        types.insert(HKObjectType.workoutType())

        return types
    }()

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        isAuthorized = true
    }

    // MARK: - Fetch All Today Data

    func fetchAllTodayData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTodayActivity() }
            group.addTask { await self.fetchBodyMeasurements() }
            group.addTask { await self.fetchVitals() }
            group.addTask { await self.fetchSleep() }
            group.addTask { await self.fetchTodayWorkouts() }
        }
    }

    // MARK: - Activity

    private func fetchTodayActivity() async {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        async let active = fetchCumulativeSum(.activeEnergyBurned, predicate: predicate, unit: .kilocalorie())
        async let resting = fetchCumulativeSum(.basalEnergyBurned, predicate: predicate, unit: .kilocalorie())
        async let stepCount = fetchCumulativeSum(.stepCount, predicate: predicate, unit: .count())
        async let exercise = fetchCumulativeSum(.appleExerciseTime, predicate: predicate, unit: .minute())

        let (a, r, s, e) = await (active, resting, stepCount, exercise)
        activeCalories = a
        restingCalories = r
        steps = Int(s)
        exerciseMinutes = e
    }

    // MARK: - Body Measurements

    private func fetchBodyMeasurements() async {
        async let w = fetchLatestQuantity(.bodyMass, unit: .gramUnit(with: .kilo))
        async let bf = fetchLatestQuantity(.bodyFatPercentage, unit: .percent())
        async let h = fetchLatestQuantity(.height, unit: .meterUnit(with: .centi))
        async let lbm = fetchLatestQuantity(.leanBodyMass, unit: .gramUnit(with: .kilo))
        async let b = fetchLatestQuantity(.bodyMassIndex, unit: .count())

        let (wv, bfv, hv, lbmv, bv) = await (w, bf, h, lbm, b)
        weight = wv
        bodyFatPercentage = bfv * 100
        height = hv
        leanBodyMass = lbmv
        bmi = bv
    }

    // MARK: - Vitals

    private func fetchVitals() async {
        async let hr = fetchLatestQuantity(.heartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let rhr = fetchLatestQuantity(.restingHeartRate, unit: HKUnit.count().unitDivided(by: .minute()))
        async let hrvVal = fetchLatestQuantity(.heartRateVariabilitySDNN, unit: .secondUnit(with: .milli))
        async let vo2 = fetchLatestQuantity(.vo2Max, unit: HKUnit(from: "ml/kg*min"))
        async let spo2 = fetchLatestQuantity(.oxygenSaturation, unit: .percent())
        async let rr = fetchLatestQuantity(.respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()))

        let (hrv1, rhrv, hrvv, vo2v, spo2v, rrv) = await (hr, rhr, hrvVal, vo2, spo2, rr)
        heartRate = hrv1
        restingHeartRate = rhrv
        hrv = hrvv
        vo2Max = vo2v
        bloodOxygen = spo2v * 100
        respiratoryRate = rrv
    }

    // MARK: - Sleep

    private func fetchSleep() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)

        let descriptor = HKSampleQueryDescriptor<HKCategorySample>(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate)]
        )

        guard let samples = try? await descriptor.result(for: healthStore) else { return }

        var summary = SleepSummary.empty
        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                summary.rem += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                summary.deep += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                summary.core += duration
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                summary.awake += duration
            default:
                summary.total += duration
            }
        }
        summary.total = summary.rem + summary.deep + summary.core

        sleepStages = summary
        sleepHours = summary.total
    }

    // MARK: - Workouts

    private func fetchTodayWorkouts() async {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        let descriptor = HKSampleQueryDescriptor<HKWorkout>(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)]
        )

        guard let workouts = try? await descriptor.result(for: healthStore) else { return }

        todayWorkouts = workouts.map { workout in
            WorkoutSummary(
                id: workout.uuid,
                type: workoutTypeName(workout.workoutActivityType),
                duration: workout.duration,
                calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                startDate: workout.startDate,
                endDate: workout.endDate,
                heartRateAvg: nil
            )
        }

        latestWorkout = todayWorkouts.first

        // Weekly workout minutes
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let weekPredicate = HKQuery.predicateForSamples(withStart: weekStart, end: now)
        let weekDescriptor = HKSampleQueryDescriptor<HKWorkout>(
            predicates: [.workout(weekPredicate)],
            sortDescriptors: []
        )
        if let weekWorkouts = try? await weekDescriptor.result(for: healthStore) {
            weeklyWorkoutMinutes = weekWorkouts.reduce(0) { $0 + $1.duration / 60 }
        }
    }

    /// Detect if a workout just finished (for plan adaptation)
    func detectRecentWorkout() async -> WorkoutSummary? {
        let thirtyMinAgo = Date().addingTimeInterval(-1800)
        let predicate = HKQuery.predicateForSamples(withStart: thirtyMinAgo, end: .now)
        let descriptor = HKSampleQueryDescriptor<HKWorkout>(
            predicates: [.workout(predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )
        guard let workouts = try? await descriptor.result(for: healthStore),
              let latest = workouts.first else { return nil }

        return WorkoutSummary(
            id: latest.uuid,
            type: workoutTypeName(latest.workoutActivityType),
            duration: latest.duration,
            calories: latest.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
            startDate: latest.startDate,
            endDate: latest.endDate,
            heartRateAvg: nil
        )
    }

    // MARK: - Health Context for AI

    func healthContext() -> HealthContext {
        HealthContext(
            activeCalories: activeCalories,
            restingCalories: restingCalories,
            steps: steps,
            exerciseMinutes: exerciseMinutes,
            weight: weight,
            bodyFatPercentage: bodyFatPercentage,
            heartRate: heartRate,
            restingHeartRate: restingHeartRate,
            hrv: hrv,
            vo2Max: vo2Max,
            sleepHours: sleepHours,
            sleepQuality: sleepStages.deep > 1.5 ? .good : (sleepHours > 6 ? .fair : .poor),
            recentWorkout: latestWorkout,
            weeklyWorkoutMinutes: weeklyWorkoutMinutes
        )
    }

    // MARK: - Helpers

    private func fetchCumulativeSum(_ identifier: HKQuantityTypeIdentifier, predicate: NSPredicate, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum
        )
        let result = try? await descriptor.result(for: healthStore)
        return result?.sumQuantity()?.doubleValue(for: unit) ?? 0
    }

    private func fetchLatestQuantity(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return 0 }
        let descriptor = HKSampleQueryDescriptor<HKQuantitySample>(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        guard let samples = try? await descriptor.result(for: healthStore),
              let sample = samples.first else { return 0 }
        return sample.quantity.doubleValue(for: unit)
    }

    private func workoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength"
        case .yoga: return "Yoga"
        case .swimming: return "Swimming"
        case .highIntensityIntervalTraining: return "HIIT"
        case .coreTraining: return "Core"
        case .crossTraining: return "Cross Training"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .pilates: return "Pilates"
        default: return "Workout"
        }
    }
}

// MARK: - Health Context (for AI Engine)

struct HealthContext {
    let activeCalories: Double
    let restingCalories: Double
    let steps: Int
    let exerciseMinutes: Double
    let weight: Double
    let bodyFatPercentage: Double
    let heartRate: Double
    let restingHeartRate: Double
    let hrv: Double
    let vo2Max: Double
    let sleepHours: Double
    let sleepQuality: SleepQuality
    let recentWorkout: HealthManager.WorkoutSummary?
    let weeklyWorkoutMinutes: Double

    enum SleepQuality {
        case good, fair, poor
    }

    var isPostWorkout: Bool {
        guard let workout = recentWorkout else { return false }
        return Date().timeIntervalSince(workout.endDate) < 3600
    }

    var isGymDay: Bool {
        recentWorkout != nil || exerciseMinutes > 30
    }

    var isLowSleep: Bool {
        sleepHours < 6
    }

    var totalBurned: Double {
        activeCalories + restingCalories
    }
}
