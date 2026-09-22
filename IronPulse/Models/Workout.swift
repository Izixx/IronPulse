import Foundation
import SwiftData

@Model
public final class Workout {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    public var notes: String
    public var feeling: Int? // 1 à 5
    public var routineName: String?

    @Relationship(deleteRule: .cascade)
    public var exercises: [WorkoutExercise]

    public init(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        notes: String = "",
        feeling: Int? = 4,
        routineName: String? = nil,
        exercises: [WorkoutExercise] = []
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
        self.feeling = feeling
        self.routineName = routineName
        self.exercises = exercises
    }

    public var isCompleted: Bool {
        endDate != nil
    }

    public var duration: TimeInterval {
        guard let endDate = endDate else {
            return Date().timeIntervalSince(startDate)
        }
        return endDate.timeIntervalSince(startDate)
    }

    public var durationFormatted: String {
        let seconds = Int(duration)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(max(1, minutes)) min"
        }
    }

    public var totalVolume: Double {
        exercises.reduce(0.0) { $0 + $1.totalVolume }
    }

    public var totalSetsCompleted: Int {
        exercises.reduce(0) { $0 + $1.completedSets.count }
    }

    public var totalRepsCompleted: Int {
        exercises.reduce(0) { total, we in
            total + we.completedSets.reduce(0) { $0 + $1.reps }
        }
    }

    public var muscleGroupsWorked: [MuscleGroup] {
        var set = Set<MuscleGroup>()
        for ex in exercises {
            for m in ex.muscleGroups {
                set.insert(m)
            }
        }
        return Array(set)
    }
}
