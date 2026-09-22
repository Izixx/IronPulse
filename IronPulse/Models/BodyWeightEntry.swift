import Foundation
import SwiftData

@Model
public final class BodyWeightEntry {
    public var id: UUID
    public var date: Date
    public var weightKg: Double
    public var notes: String

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double,
        notes: String = ""
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
    }
}
