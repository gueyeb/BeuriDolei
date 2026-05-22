import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    private let store = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard isAvailable else { completion(false); return }
        store.requestAuthorization(toShare: [workoutType], read: []) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func saveWorkout(_ session: PlankSession, completion: ((Bool) -> Void)? = nil) {
        guard isAvailable else { return }

        let calories = estimatedCalories(duration: session.duration)
        let energyBurned = calories.map {
            HKQuantity(unit: .kilocalorie(), doubleValue: $0)
        }

        let workout = HKWorkout(
            activityType: .coreTraining,
            start: session.startedAt,
            end: session.endedAt,
            duration: session.duration,
            totalEnergyBurned: energyBurned,
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "BeuriDolei"]
        )

        store.save(workout) { success, _ in
            DispatchQueue.main.async { completion?(success) }
        }
    }

    // ~3.5 MET for plank × body weight ~70kg ÷ 3600 × duration
    private func estimatedCalories(duration: TimeInterval) -> Double? {
        let kcal = 3.5 * 70.0 / 3600.0 * duration
        return kcal > 0 ? kcal : nil
    }
}
