import Foundation
import SwiftData

@Model
public final class ExerciseSet {
    public var id: UUID
    public var setNumber: Int
    public var reps: Int
    public var weightKg: Double
    public var rpe: Double?
    public var isCompleted: Bool
    public var isWarmup: Bool
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        setNumber: Int = 1,
        reps: Int = 10,
        weightKg: Double = 0.0,
        rpe: Double? = nil,
        isCompleted: Bool = false,
        isWarmup: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
        self.rpe = rpe
        self.isCompleted = isCompleted
        self.isWarmup = isWarmup
        self.completedAt = completedAt
    }

    /// Volume soulevé pour cette série (kg)
    public var volume: Double {
        guard reps > 0 && weightKg > 0 else { return 0.0 }
        return Double(reps) * weightKg
    }

    /// 1RM théorique estimé d'après la formule d'Epley : Charge * (1 + Reps / 30)
    public var estimated1RM: Double {
        guard weightKg > 0 && reps > 0 else { return 0.0 }
        if reps == 1 { return weightKg }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }
}
