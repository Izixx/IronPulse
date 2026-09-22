import SwiftUI
import SwiftData

public enum TimeFilter: String, CaseIterable, Identifiable {
    case last7Days = "7 jours"
    case last30Days = "30 jours"
    case allTime = "Tout"

    public var id: String { rawValue }

    public var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .last7Days:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        case .allTime:
            return nil
        }
    }
}

public enum RecoveryStatus {
    case priority    // >= 5 jours sans sollicitation ou jamais fait
    case ready       // 48h - 5 jours de repos
    case recovering  // < 48h de repos

    public var label: String {
        switch self {
        case .priority: return "À entraîner en priorité"
        case .ready: return "Prêt"
        case .recovering: return "En récupération"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .priority: return .red
        case .ready: return .green
        case .recovering: return .orange
        }
    }

    public var sfIcon: String {
        switch self {
        case .priority: return "exclamationmark.circle.fill"
        case .ready: return "checkmark.circle.fill"
        case .recovering: return "clock.fill"
        }
    }
}

public struct MuscleReadinessItem: Identifiable {
    public var id: String { muscle.rawValue }
    public let muscle: MuscleGroup
    public let lastTrainedDate: Date?
    public let hoursSince: Int?
    public let daysSince: Int?
    public let status: RecoveryStatus

    public var subtitle: String {
        guard let days = daysSince else {
            return "Jamais entraîné"
        }
        if days == 0 {
            if let hours = hoursSince {
                return "Entraîné il y a \(hours)h"
            }
            return "Entraîné aujourd'hui"
        } else if days == 1 {
            return "Entraîné hier"
        } else {
            return "Entraîné il y a \(days) jours"
        }
    }
}

public struct MuscleVolumeItem: Identifiable {
    public var id: String { muscle.rawValue }
    public let muscle: MuscleGroup
    public let totalVolumeKg: Double
    public let totalSets: Int
}

public struct HeatmapDay: Identifiable {
    public var id: Date { date }
    public let date: Date
    public let workoutCount: Int
    public let volumeKg: Double

    public var intensityLevel: Int {
        if workoutCount == 0 { return 0 }
        if volumeKg < 3000 { return 1 }
        if volumeKg < 7000 { return 2 }
        if volumeKg < 15000 { return 3 }
        return 4
    }
}

public struct ExerciseSessionProgress: Identifiable {
    public var id: UUID
    public let date: Date
    public let maxWeight: Double
    public let bestEstimated1RM: Double
    public let totalVolume: Double
}

public struct ExercisePersonalRecords {
    public var maxWeight: Double = 0.0
    public var best1RM: Double = 0.0
    public var bestVolume: Double = 0.0
    public var totalTimesPerformed: Int = 0
}

public struct GlobalStats {
    public var totalWorkouts: Int = 0
    public var totalTonnageTonnes: Double = 0.0
    public var totalSets: Int = 0
    public var weeklyAverageFrequency: Double = 0.0
}

public struct StatisticsEngine {

    // MARK: - 1. « Quoi entraîner aujourd'hui ? »
    public static func computeMuscleReadiness(from workouts: [Workout]) -> [MuscleReadinessItem] {
        let calendar = Calendar.current
        let now = Date()

        var latestDatePerMuscle: [MuscleGroup: Date] = [:]

        // Trier par date décroissante
        let sortedWorkouts = workouts.sorted { $0.startDate > $1.startDate }

        for workout in sortedWorkouts {
            for exercise in workout.exercises {
                for muscle in exercise.muscleGroups {
                    if latestDatePerMuscle[muscle] == nil {
                        latestDatePerMuscle[muscle] = workout.startDate
                    }
                }
            }
        }

        var items: [MuscleReadinessItem] = []

        for muscle in MuscleGroup.allCases {
            if let lastDate = latestDatePerMuscle[muscle] {
                let diffSeconds = now.timeIntervalSince(lastDate)
                let hours = Int(diffSeconds / 3600)
                let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: now)).day ?? 0

                let status: RecoveryStatus
                if days >= 5 {
                    status = .priority
                } else if hours >= 48 {
                    status = .ready
                } else {
                    status = .recovering
                }

                items.append(MuscleReadinessItem(
                    muscle: muscle,
                    lastTrainedDate: lastDate,
                    hoursSince: hours,
                    daysSince: days,
                    status: status
                ))
            } else {
                items.append(MuscleReadinessItem(
                    muscle: muscle,
                    lastTrainedDate: nil,
                    hoursSince: nil,
                    daysSince: nil,
                    status: .priority
                ))
            }
        }

        // Trier : Priorité en premier, puis Prêt (le plus longtemps au repos), puis En récupération
        return items.sorted { a, b in
            let scoreA = recoveryScore(a)
            let scoreB = recoveryScore(b)
            return scoreA > scoreB
        }
    }

    private static func recoveryScore(_ item: MuscleReadinessItem) -> Int {
        switch item.status {
        case .priority:
            return 1000 + (item.daysSince ?? 999)
        case .ready:
            return 500 + (item.daysSince ?? 0)
        case .recovering:
            return item.hoursSince ?? 0
        }
    }

    // MARK: - 2. Volume par Groupe Musculaire
    public static func computeMuscleVolume(from workouts: [Workout], filter: TimeFilter) -> [MuscleVolumeItem] {
        let filteredWorkouts: [Workout]

        if let startDate = filter.startDate {
            filteredWorkouts = workouts.filter { $0.startDate >= startDate }
        } else {
            filteredWorkouts = workouts
        }

        var volumePerMuscle: [MuscleGroup: Double] = [:]
        var setsPerMuscle: [MuscleGroup: Int] = [:]

        for w in filteredWorkouts {
            for we in w.exercises {
                let muscles = we.muscleGroups
                guard !muscles.isEmpty else { continue }
                let volSplit = we.totalVolume / Double(muscles.count)
                let setsSplit = we.completedSets.count

                for m in muscles {
                    volumePerMuscle[m, default: 0.0] += volSplit
                    setsPerMuscle[m, default: 0] += setsSplit
                }
            }
        }

        var items = MuscleGroup.allCases.map { muscle in
            MuscleVolumeItem(
                muscle: muscle,
                totalVolumeKg: volumePerMuscle[muscle] ?? 0.0,
                totalSets: setsPerMuscle[muscle] ?? 0
            )
        }

        // Trier par volume décroissant
        items.sort { $0.totalVolumeKg > $1.totalVolumeKg }
        return items
    }

    // MARK: - 3. Calendrier Heatmap (Style GitHub Contributions)
    public static func computeHeatmap(from workouts: [Workout], weeksCount: Int = 16) -> [HeatmapDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Trouver le lundi il y a `weeksCount` semaines
        let daysToSubtract = (weeksCount * 7) - 1
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: today) else {
            return []
        }

        // Indexer les séances par date normalisée
        var workoutsByDay: [Date: [Workout]] = [:]
        for w in workouts {
            let day = calendar.startOfDay(for: w.startDate)
            workoutsByDay[day, default: []].append(w)
        }

        var heatmapDays: [HeatmapDay] = []
        var currentDate = startDate

        while currentDate <= today {
            let dayWorkouts = workoutsByDay[currentDate] ?? []
            let totalVol = dayWorkouts.reduce(0.0) { $0 + $1.totalVolume }
            heatmapDays.append(HeatmapDay(
                date: currentDate,
                workoutCount: dayWorkouts.count,
                volumeKg: totalVol
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return heatmapDays
    }

    // MARK: - 4. Progression et Records Personnels d'un Exercice
    public static func computeExerciseProgression(exerciseName: String, from workouts: [Workout]) -> (history: [ExerciseSessionProgress], records: ExercisePersonalRecords) {
        let sortedWorkouts = workouts.sorted { $0.startDate < $1.startDate }
        var history: [ExerciseSessionProgress] = []
        var records = ExercisePersonalRecords()

        for w in sortedWorkouts {
            if let we = w.exercises.first(where: { $0.exerciseName.caseInsensitiveCompare(exerciseName) == .orderedSame }) {
                guard !we.completedSets.isEmpty else { continue }
                let maxW = we.maxWeight
                let best1RM = we.bestEstimated1RM
                let vol = we.totalVolume

                history.append(ExerciseSessionProgress(
                    id: we.id,
                    date: w.startDate,
                    maxWeight: maxW,
                    bestEstimated1RM: best1RM,
                    totalVolume: vol
                ))

                records.maxWeight = max(records.maxWeight, maxW)
                records.best1RM = max(records.best1RM, best1RM)
                records.bestVolume = max(records.bestVolume, vol)
                records.totalTimesPerformed += 1
            }
        }

        return (history, records)
    }

    // MARK: - 5. Statistiques Globales
    public static func computeGlobalStats(from workouts: [Workout]) -> GlobalStats {
        let totalCount = workouts.count
        let totalVolKg = workouts.reduce(0.0) { $0 + $1.totalVolume }
        let totalSets = workouts.reduce(0) { $0 + $1.totalSetsCompleted }

        // Fréquence hebdomadaire sur les 4 dernières semaines
        let calendar = Calendar.current
        let fourWeeksAgo = calendar.date(byAdding: .day, value: -28, to: Date()) ?? Date()
        let recentWorkouts = workouts.filter { $0.startDate >= fourWeeksAgo }
        let weeklyAvg = Double(recentWorkouts.count) / 4.0

        return GlobalStats(
            totalWorkouts: totalCount,
            totalTonnageTonnes: totalVolKg / 1000.0,
            totalSets: totalSets,
            weeklyAverageFrequency: weeklyAvg
        )
    }
}
