import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var activeCalories: Double = 0
    @Published var restingCalories: Double = 0
    @Published var steps: Int = 0
    @Published var latestWorkout: HKWorkout?
    @Published var sleepHours: Double = 0
    @Published var heartRate: Double = 0
    @Published var isAuthorized: Bool = false

    // HealthKit types to read
    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        // Activity
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { types.insert(activeEnergy) }
        if let basalEnergy = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) { types.insert(basalEnergy) }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) { types.insert(steps) }
        // Body
        if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) { types.insert(weight) }
        if let bodyFat = HKObjectType.quantityType(forIdentifier: .bodyFatPercentage) { types.insert(bodyFat) }
        if let height = HKObjectType.quantityType(forIdentifier: .height) { types.insert(height) }
        // Vitals
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) { types.insert(heartRate) }
        if let restingHR = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(restingHR) }
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let vo2Max = HKObjectType.quantityType(forIdentifier: .vo2Max) { types.insert(vo2Max) }
        // Sleep & Nutrition
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        if let water = HKObjectType.quantityType(forIdentifier: .dietaryWater) { types.insert(water) }
        // Workouts
        types.insert(HKObjectType.workoutType())
        return types
    }()

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        await MainActor.run { isAuthorized = true }
    }

    func fetchTodayActivity() async throws {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        if let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            let descriptor = HKStatisticsQueryDescriptor(
                predicate: HKSamplePredicate<HKQuantitySample>.quantitySample(type: activeEnergyType, predicate: predicate),
                options: .cumulativeSum
            )
            let result = try await descriptor.result(for: healthStore)
            let value = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            await MainActor.run { activeCalories = value }
        }
    }
}
