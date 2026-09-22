import Foundation
import SwiftData

// MARK: - DTOs de Sauvegarde (Indépendants du schéma SwiftData pour garantir la compatibilité)
public struct BackupPayload: Codable {
    public var exportDate: Date
    public var appVersion: String
    public var workouts: [WorkoutBackupDTO]
    public var customExercises: [ExerciseBackupDTO]
    public var routines: [RoutineBackupDTO]
    public var weightEntries: [BodyWeightBackupDTO]
}

public struct WorkoutBackupDTO: Codable {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    public var notes: String
    public var feeling: Int?
    public var routineName: String?
    public var exercises: [WorkoutExerciseBackupDTO]
}

public struct WorkoutExerciseBackupDTO: Codable {
    public var order: Int
    public var exerciseName: String
    public var muscleGroups: [String]
    public var notes: String
    public var sets: [ExerciseSetBackupDTO]
}

public struct ExerciseSetBackupDTO: Codable {
    public var setNumber: Int
    public var reps: Int
    public var weightKg: Double
    public var rpe: Double?
    public var isCompleted: Bool
    public var isWarmup: Bool
}

public struct ExerciseBackupDTO: Codable {
    public var name: String
    public var muscleGroups: [String]
    public var equipment: String
    public var category: String
    public var isCustom: Bool
    public var notes: String
}

public struct RoutineBackupDTO: Codable {
    public var name: String
    public var details: String
    public var isActive: Bool
    public var currentDayIndex: Int
    public var days: [RoutineDayBackupDTO]
}

public struct RoutineDayBackupDTO: Codable {
    public var dayOrder: Int
    public var name: String
    public var muscleGroups: [String]
    public var exerciseNames: [String]
}

public struct BodyWeightBackupDTO: Codable {
    public var date: Date
    public var weightKg: Double
    public var notes: String
}

// MARK: - BackupService
public struct BackupService {
    
    // MARK: - Export JSON
    @MainActor
    public static func exportAllDataToJSON(modelContext: ModelContext) throws -> URL {
        let workoutFetch = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.startDate, order: .forward)])
        let workouts = try modelContext.fetch(workoutFetch)

        let exerciseFetch = FetchDescriptor<Exercise>()
        let exercises = try modelContext.fetch(exerciseFetch)

        let routineFetch = FetchDescriptor<Routine>()
        let routines = try modelContext.fetch(routineFetch)

        let weightFetch = FetchDescriptor<BodyWeightEntry>(sortBy: [SortDescriptor(\.date, order: .forward)])
        let weights = try modelContext.fetch(weightFetch)

        let workoutDTOs = workouts.map { w in
            WorkoutBackupDTO(
                id: w.id,
                startDate: w.startDate,
                endDate: w.endDate,
                notes: w.notes,
                feeling: w.feeling,
                routineName: w.routineName,
                exercises: w.exercises.sorted(by: { $0.order < $1.order }).map { we in
                    WorkoutExerciseBackupDTO(
                        order: we.order,
                        exerciseName: we.exerciseName,
                        muscleGroups: we.muscleGroupRawValues,
                        notes: we.notes,
                        sets: we.sets.sorted(by: { $0.setNumber < $1.setNumber }).map { s in
                            ExerciseSetBackupDTO(
                                setNumber: s.setNumber,
                                reps: s.reps,
                                weightKg: s.weightKg,
                                rpe: s.rpe,
                                isCompleted: s.isCompleted,
                                isWarmup: s.isWarmup
                            )
                        }
                    )
                }
            )
        }

        let customExerciseDTOs = exercises.filter { $0.isCustom }.map { e in
            ExerciseBackupDTO(
                name: e.name,
                muscleGroups: e.muscleGroupRawValues,
                equipment: e.equipment,
                category: e.category,
                isCustom: e.isCustom,
                notes: e.notes
            )
        }

        let routineDTOs = routines.map { r in
            RoutineBackupDTO(
                name: r.name,
                details: r.details,
                isActive: r.isActive,
                currentDayIndex: r.currentDayIndex,
                days: r.sortedDays.map { d in
                    RoutineDayBackupDTO(
                        dayOrder: d.dayOrder,
                        name: d.name,
                        muscleGroups: d.muscleGroupRawValues,
                        exerciseNames: d.exerciseNames
                    )
                }
            )
        }

        let weightDTOs = weights.map {
            BodyWeightBackupDTO(date: $0.date, weightKg: $0.weightKg, notes: $0.notes)
        }

        let payload = BackupPayload(
            exportDate: Date(),
            appVersion: "1.0.0",
            workouts: workoutDTOs,
            customExercises: customExerciseDTOs,
            routines: routineDTOs,
            weightEntries: weightDTOs
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let filename = "IronPulse_Backup_\(dateFormatter.string(from: Date())).json"

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: tempURL)
        return tempURL
    }

    // MARK: - Import JSON
    @MainActor
    public static func importDataFromJSON(url: URL, modelContext: ModelContext) throws -> (workoutsCount: Int, routinesCount: Int) {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        // 1. Importer les exercices personnalisés
        for exDTO in payload.customExercises {
            let name = exDTO.name
            let fetch = FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == name })
            let existing = (try? modelContext.fetch(fetch))?.first
            if existing == nil {
                let newEx = Exercise(
                    name: exDTO.name,
                    muscleGroups: exDTO.muscleGroups.compactMap { MuscleGroup(rawValue: $0) },
                    equipment: exDTO.equipment,
                    category: exDTO.category,
                    isCustom: true,
                    notes: exDTO.notes
                )
                modelContext.insert(newEx)
            }
        }

        // 2. Importer les séances (éviter les doublons par date de début)
        var importedWorkouts = 0
        let existingWorkouts = try modelContext.fetch(FetchDescriptor<Workout>())
        let existingStartDates = Set(existingWorkouts.map { Int($0.startDate.timeIntervalSince1970) })

        for wDTO in payload.workouts {
            let startStamp = Int(wDTO.startDate.timeIntervalSince1970)
            if existingStartDates.contains(startStamp) {
                continue // Déjà existante
            }

            let workout = Workout(
                id: wDTO.id,
                startDate: wDTO.startDate,
                endDate: wDTO.endDate,
                notes: wDTO.notes,
                feeling: wDTO.feeling,
                routineName: wDTO.routineName
            )

            var workoutExercises: [WorkoutExercise] = []
            for weDTO in wDTO.exercises {
                var sets: [ExerciseSet] = []
                for sDTO in weDTO.sets {
                    let set = ExerciseSet(
                        setNumber: sDTO.setNumber,
                        reps: sDTO.reps,
                        weightKg: sDTO.weightKg,
                        rpe: sDTO.rpe,
                        isCompleted: sDTO.isCompleted,
                        isWarmup: sDTO.isWarmup
                    )
                    sets.append(set)
                }
                let we = WorkoutExercise(
                    order: weDTO.order,
                    exerciseName: weDTO.exerciseName,
                    muscleGroups: weDTO.muscleGroups.compactMap { MuscleGroup(rawValue: $0) },
                    notes: weDTO.notes,
                    sets: sets
                )
                workoutExercises.append(we)
            }
            workout.exercises = workoutExercises
            modelContext.insert(workout)
            importedWorkouts += 1
        }

        // 3. Importer le poids corporel
        let existingWeights = try modelContext.fetch(FetchDescriptor<BodyWeightEntry>())
        let existingWeightDays = Set(existingWeights.map { Calendar.current.startOfDay(for: $0.date) })

        for bw in payload.weightEntries {
            let day = Calendar.current.startOfDay(for: bw.date)
            if !existingWeightDays.contains(day) {
                let entry = BodyWeightEntry(date: bw.date, weightKg: bw.weightKg, notes: bw.notes)
                modelContext.insert(entry)
            }
        }

        try modelContext.save()
        return (importedWorkouts, payload.routines.count)
    }

    // MARK: - Export CSV (Excel / Numbers)
    @MainActor
    public static func exportWorkoutsToCSV(modelContext: ModelContext) throws -> URL {
        let workoutFetch = FetchDescriptor<Workout>(sortBy: [SortDescriptor(\.startDate, order: .ascending)])
        let workouts = try modelContext.fetch(workoutFetch)

        var csvString = "Date;Heure;Seance;Exercice;Muscles;Serie;Reps;PoidsKg;RPE;Echauffement;Valide;VolumeKg\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        for w in workouts {
            let dateStr = dateFormatter.string(from: w.startDate)
            let timeStr = timeFormatter.string(from: w.startDate)
            let sessionName = (w.routineName?.isEmpty == false ? w.routineName! : "Entraînement").replacingOccurrences(of: ";", with: " ")

            for we in w.exercises.sorted(by: { $0.order < $1.order }) {
                let exName = we.exerciseName.replacingOccurrences(of: ";", with: " ")
                let muscles = we.muscleGroups.map { $0.displayName }.joined(by: "/").replacingOccurrences(of: ";", with: " ")

                for s in we.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                    let rpeStr = s.rpe != nil ? String(format: "%.1f", s.rpe!) : ""
                    let warmupStr = s.isWarmup ? "Oui" : "Non"
                    let completedStr = s.isCompleted ? "Oui" : "Non"
                    let volStr = String(format: "%.1f", s.volume)

                    let row = "\(dateStr);\(timeStr);\(sessionName);\(exName);\(muscles);\(s.setNumber);\(s.reps);\(s.weightKg);\(rpeStr);\(warmupStr);\(completedStr);\(volStr)\n"
                    csvString.append(row)
                }
            }
        }

        let filename = "IronPulse_Export_\(dateFormatter.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try csvString.write(to: tempURL, atomically: true, encoding: .utf8)
        return tempURL
    }
}
