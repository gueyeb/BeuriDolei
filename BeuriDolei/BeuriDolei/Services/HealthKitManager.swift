import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    private let store = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()
    private let externalUUIDKey = HKMetadataKeyExternalUUID
    private let variantKey = "BeuriDoleiVariant"

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            DispatchQueue.main.async { completion(false) }
            return
        }

        store.requestAuthorization(toShare: [workoutType], read: [workoutType]) { granted, _ in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func saveWorkout(_ session: PlankSession, completion: ((Bool) -> Void)? = nil) {
        guard isAvailable else {
            DispatchQueue.main.async { completion?(false) }
            return
        }

        hasExistingWorkout(for: session) { [weak self] exists in
            guard let self else {
                completion?(false)
                return
            }

            if exists {
                completion?(true)
                return
            }

            let calories = self.estimatedCalories(duration: session.duration)
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
                metadata: self.metadata(for: session)
            )

            self.store.save(workout) { success, _ in
                DispatchQueue.main.async {
                    completion?(success)
                }
            }
        }
    }

    private func hasExistingWorkout(for session: PlankSession, completion: @escaping (Bool) -> Void) {
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: externalUUIDKey,
            operatorType: .equalTo,
            value: session.id.uuidString
        )
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: 1,
            sortDescriptors: nil
        ) { _, samples, _ in
            DispatchQueue.main.async {
                completion(!(samples?.isEmpty ?? true))
            }
        }

        store.execute(query)
    }

    private func metadata(for session: PlankSession) -> [String: Any] {
        [
            HKMetadataKeyWorkoutBrandName: "BeuriDolei",
            externalUUIDKey: session.id.uuidString,
            variantKey: session.variant.rawValue,
        ]
    }

    // ~3.5 MET for plank × body weight ~70kg ÷ 3600 × duration
    private func estimatedCalories(duration: TimeInterval) -> Double? {
        let kcal = 3.5 * 70.0 / 3600.0 * duration
        return kcal > 0 ? kcal : nil
    }
}
