import Foundation
import HealthKit

public final class HealthKitManager {
    public static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    public private(set) var isAuthorized = false

    private init() {}

    public var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard isAvailable else {
            completion(false)
            return
        }

        let workoutType = HKObjectType.workoutType()
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            completion(false)
            return
        }

        let typesToWrite: Set<HKSampleType> = [workoutType, bodyMassType]
        let typesToRead: Set<HKObjectType> = [workoutType, bodyMassType]

        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                completion(success)
            }
        }
    }

    // MARK: - Enregistrer un entraînement de musculation
    public func saveWorkout(
        startDate: Date,
        endDate: Date,
        totalEnergyBurnedCalories: Double? = nil,
        completion: @escaping (Bool, Error?) -> Void = { _, _ in }
    ) {
        guard isAvailable else {
            completion(false, nil)
            return
        }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())

        builder.beginCollection(withStart: startDate) { success, error in
            guard success else {
                DispatchQueue.main.async { completion(false, error) }
                return
            }

            builder.endCollection(withEnd: endDate) { success, error in
                guard success else {
                    DispatchQueue.main.async { completion(false, error) }
                    return
                }

                builder.finishWorkout { workout, error in
                    DispatchQueue.main.async {
                        completion(workout != nil, error)
                    }
                }
            }
        }
    }

    // MARK: - Enregistrer le poids corporel
    public func saveBodyWeight(weightKg: Double, date: Date = Date(), completion: @escaping (Bool, Error?) -> Void = { _, _ in }) {
        guard isAvailable, let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(false, nil)
            return
        }

        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: bodyMassType, quantity: quantity, start: date, end: date)

        healthStore.save(sample) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }

    // MARK: - Lire le dernier poids corporel enregistré
    public func fetchLatestBodyWeight(completion: @escaping (Double?) -> Void) {
        guard isAvailable, let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            completion(nil)
            return
        }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: bodyMassType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            let weightKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            DispatchQueue.main.async {
                completion(weightKg)
            }
        }

        healthStore.execute(query)
    }
}
