import Foundation
import SwiftData

@Model
public final class RoutineDay {
    public var id: UUID
    public var dayOrder: Int
    public var name: String
    public var muscleGroupRawValues: [String]
    public var exerciseNames: [String]

    public init(
        id: UUID = UUID(),
        dayOrder: Int = 0,
        name: String,
        muscleGroups: [MuscleGroup] = [],
        exerciseNames: [String] = []
    ) {
        self.id = id
        self.dayOrder = dayOrder
        self.name = name
        self.muscleGroupRawValues = muscleGroups.map { $0.rawValue }
        self.exerciseNames = exerciseNames
    }

    public var muscleGroups: [MuscleGroup] {
        get {
            muscleGroupRawValues.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            muscleGroupRawValues = newValue.map { $0.rawValue }
        }
    }
}

@Model
public final class Routine {
    public var id: UUID
    public var name: String
    public var details: String
    public var isActive: Bool
    public var currentDayIndex: Int
    
    @Relationship(deleteRule: .cascade)
    public var days: [RoutineDay]

    public init(
        id: UUID = UUID(),
        name: String,
        details: String = "",
        isActive: Bool = false,
        currentDayIndex: Int = 0,
        days: [RoutineDay] = []
    ) {
        self.id = id
        self.name = name
        self.details = details
        self.isActive = isActive
        self.currentDayIndex = currentDayIndex
        self.days = days
    }

    public var sortedDays: [RoutineDay] {
        days.sorted { $0.dayOrder < $1.dayOrder }
    }

    public var currentDay: RoutineDay? {
        let sorted = sortedDays
        guard !sorted.isEmpty else { return nil }
        let idx = currentDayIndex % sorted.count
        return sorted[idx]
    }

    public func advanceCycle() {
        let sorted = sortedDays
        guard !sorted.isEmpty else { return }
        currentDayIndex = (currentDayIndex + 1) % sorted.count
    }
}
