import Foundation
import SwiftData

@Model
public final class Exercise {
    public var id: UUID
    public var name: String
    public var muscleGroupRawValues: [String]
    public var equipment: String
    public var category: String
    public var isCustom: Bool
    public var notes: String

    public init(
        id: UUID = UUID(),
        name: String,
        muscleGroups: [MuscleGroup] = [],
        equipment: String = "Barre",
        category: String = "Polyarticulaire",
        isCustom: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRawValues = muscleGroups.map { $0.rawValue }
        self.equipment = equipment
        self.category = category
        self.isCustom = isCustom
        self.notes = notes
    }

    public var muscleGroups: [MuscleGroup] {
        get {
            muscleGroupRawValues.compactMap { MuscleGroup(rawValue: $0) }
        }
        set {
            muscleGroupRawValues = newValue.map { $0.rawValue }
        }
    }

    public var primaryMuscle: MuscleGroup? {
        muscleGroups.first
    }
}
