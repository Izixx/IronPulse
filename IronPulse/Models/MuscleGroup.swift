import SwiftUI

public enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case biceps = "biceps"
    case triceps = "triceps"
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case calves = "calves"
    case glutes = "glutes"
    case abs = "abs"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chest: return "Pectoraux"
        case .back: return "Dos"
        case .shoulders: return "Épaules"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quadriceps: return "Quadriceps"
        case .hamstrings: return "Ischio-jambiers"
        case .calves: return "Mollets"
        case .glutes: return "Fessiers"
        case .abs: return "Abdominaux"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .chest: return "shield.fill"
        case .back: return "figure.gymnastics"
        case .shoulders: return "arrow.up.left.and.arrow.down.right"
        case .biceps: return "figure.arms.open"
        case .triceps: return "bolt.horizontal.fill"
        case .quadriceps: return "figure.walk"
        case .hamstrings: return "figure.run"
        case .calves: return "shoeprints.fill"
        case .glutes: return "flame.fill"
        case .abs: return "square.grid.2x2.fill"
        }
    }

    public var color: Color {
        switch self {
        case .chest: return Color.orange
        case .back: return Color.blue
        case .shoulders: return Color.indigo
        case .biceps: return Color.red
        case .triceps: return Color.pink
        case .quadriceps: return Color.green
        case .hamstrings: return Color.teal
        case .calves: return Color.mint
        case .glutes: return Color.purple
        case .abs: return Color.yellow
        }
    }
}
