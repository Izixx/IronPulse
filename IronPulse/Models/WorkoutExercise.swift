import Foundation
import SwiftData

@Model
public final class WorkoutExercise {
    public var id: UUID
    public var order: Int
    public var exerciseId: UUID?
    public var exerciseName: String
    public var muscleGroupRawValues: [String]
    public var notes: String
    
    @Relationship(deleteRule: .cascade)
    public var sets: [ExerciseSet]

    public init(
        id: UUID = UUID(),
        order: Int = 0,
        exerciseId: UUID? = nil,
        exerciseName: String,
        muscleGroups: [MuscleGroup] = [],
        notes: String = "",
        sets: [ExerciseSet] = []
    ) {
        self.id = id
        self.order = order
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.muscleGroupRawValues = muscleGroups.map { $0.rawValue }
        self.notes = notes
        self.sets = sets
    }

    public var muscleGroups: [MuscleGroup] {
        get {
            muscleGroupRawValues.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            muscleGroupRawValues = newValue.map { $0.rawValue }
        }
    }

    public var completedSets: [ExerciseSet] {
        sets.filter { $0.isCompleted }
    }

    public var totalVolume: Double {
        completedSets.reduce(0.0) { $0 + $1.volume }
    }

    public var maxWeight: Double {
        completedSets.map { $0.weightKg }.max() ?? 0.0
    }

    public var bestEstimated1RM: Double {
        completedSets.map { $0.estimated1RM }.max() ?? 0.0
    }
}
