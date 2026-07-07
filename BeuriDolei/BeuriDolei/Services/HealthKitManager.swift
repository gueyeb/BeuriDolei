import Foundation
import HealthKit

final class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    private let store = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()
    private let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let externalUUIDKey = HKMetadataKeyExternalUUID
    private let variantKey = "BeuriDoleiVariant"

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            DispatchQueue.main.async { completion(false) }
            return
        }

        store.requestAuthorization(toShare: [workoutType, activeEnergyType], read: []) { granted, _ in
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

        let calories = estimatedCalories(duration: session.duration)
        let energyBurned = calories.map {
            HKQuantity(unit: .kilocalorie(), doubleValue: $0)
        }
        persistWorkout(
            session: session,
            energyBurned: energyBurned,
            completion: completion
        )
    }

    private func metadata(for session: PlankSession) -> [String: Any] {
        [
            HKMetadataKeyWorkoutBrandName: "BeuriDolei",
            externalUUIDKey: session.id.uuidString,
            variantKey: session.variant.rawValue,
        ]
    }

    private func persistWorkout(
        session: PlankSession,
        energyBurned: HKQuantity?,
        completion: ((Bool) -> Void)?
    ) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .coreTraining
        configuration.locationType = .unknown

        let builder = HKWorkoutBuilder(
            healthStore: store,
            configuration: configuration,
            device: .local()
        )

        builder.beginCollection(withStart: session.startedAt) { [weak self] success, _ in
            guard let self, success else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            self.addEnergyIfNeeded(
                energyBurned,
                to: builder,
                session: session,
                completion: completion
            )
        }
    }

    private func addEnergyIfNeeded(
        _ energyBurned: HKQuantity?,
        to builder: HKWorkoutBuilder,
        session: PlankSession,
        completion: ((Bool) -> Void)?
    ) {
        guard let energyBurned else {
            addMetadata(to: builder, session: session, completion: completion)
            return
        }

        let sample = HKQuantitySample(
            type: activeEnergyType,
            quantity: energyBurned,
            start: session.startedAt,
            end: session.endedAt
        )

        builder.add([sample]) { [weak self] success, _ in
            guard let self, success else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            self.addMetadata(to: builder, session: session, completion: completion)
        }
    }

    private func addMetadata(
        to builder: HKWorkoutBuilder,
        session: PlankSession,
        completion: ((Bool) -> Void)?
    ) {
        builder.addMetadata(metadata(for: session)) { [weak self] success, _ in
            guard let self, success else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            self.finishWorkout(builder: builder, session: session, completion: completion)
        }
    }

    private func finishWorkout(
        builder: HKWorkoutBuilder,
        session: PlankSession,
        completion: ((Bool) -> Void)?
    ) {
        builder.endCollection(withEnd: session.endedAt) { success, _ in
            guard success else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            builder.finishWorkout { workout, _ in
                DispatchQueue.main.async {
                    completion?(workout != nil)
                }
            }
        }
    }

    // ~3.5 MET for plank × body weight ~70kg ÷ 3600 × duration
    private func estimatedCalories(duration: TimeInterval) -> Double? {
        let kcal = 3.5 * 70.0 / 3600.0 * duration
        return kcal > 0 ? kcal : nil
    }
}
