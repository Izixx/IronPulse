import SwiftUI
import SwiftData

@Observable
public final class AppState {
    public static let shared = AppState()

    public var selectedTab: Int = 0
    public var activeWorkout: Workout? = nil
    public var elapsedTime: TimeInterval = 0
    public var showSummarySheet: Bool = false
    public var newlyCompletedWorkout: Workout? = nil

    private var durationTimer: Timer?

    public init() {}

    public var isWorkoutActive: Bool {
        activeWorkout != nil
    }

    public var elapsedTimeFormatted: String {
        let totalSeconds = Int(elapsedTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    public func startWorkout(routine: Routine? = nil, routineDay: RoutineDay? = nil, modelContext: ModelContext) {
        let workout = Workout(
            startDate: Date(),
            routineName: routineDay?.name ?? routine?.name ?? "Séance Libre",
            exercises: []
        )

        // Si démarré depuis une routine, préremplir les exercices
        if let day = routineDay {
            for (index, exName) in day.exerciseNames.enumerated() {
                let fetch = FetchDescriptor<Exercise>(predicate: #Predicate { $0.name == exName })
                let exercise = (try? modelContext.fetch(fetch))?.first
                let muscles = exercise?.muscleGroups ?? day.muscleGroups

                let workoutExercise = WorkoutExercise(
                    order: index,
                    exerciseId: exercise?.id,
                    exerciseName: exName,
                    muscleGroups: muscles,
                    sets: [
                        ExerciseSet(setNumber: 1, reps: 10, weightKg: 0, rpe: nil, isCompleted: false, isWarmup: false),
                        ExerciseSet(setNumber: 2, reps: 10, weightKg: 0, rpe: nil, isCompleted: false, isWarmup: false),
                        ExerciseSet(setNumber: 3, reps: 10, weightKg: 0, rpe: nil, isCompleted: false, isWarmup: false)
                    ]
                )
                workout.exercises.append(workoutExercise)
            }
        }

        modelContext.insert(workout)
        self.activeWorkout = workout
        self.elapsedTime = 0
        self.selectedTab = 1 // Aller sur l'onglet Séance

        startDurationTimer()
    }

    public func duplicateWorkout(_ previousWorkout: Workout, modelContext: ModelContext) {
        let newWorkout = Workout(
            startDate: Date(),
            notes: previousWorkout.notes,
            routineName: previousWorkout.routineName ?? "Séance Dupliquée",
            exercises: []
        )

        for we in previousWorkout.exercises.sorted(by: { $0.order < $1.order }) {
            let newWE = WorkoutExercise(
                order: we.order,
                exerciseId: we.exerciseId,
                exerciseName: we.exerciseName,
                muscleGroups: we.muscleGroups,
                sets: []
            )

            for s in we.sets.sorted(by: { $0.setNumber < $1.setNumber }) {
                let newSet = ExerciseSet(
                    setNumber: s.setNumber,
                    reps: s.reps,
                    weightKg: s.weightKg,
                    rpe: s.rpe,
                    isCompleted: false, // Réinitialisé pour la nouvelle séance
                    isWarmup: s.isWarmup
                )
                newWE.sets.append(newSet)
            }
            newWorkout.exercises.append(newWE)
        }

        modelContext.insert(newWorkout)
        self.activeWorkout = newWorkout
        self.elapsedTime = 0
        self.selectedTab = 1

        startDurationTimer()
    }

    public func cancelWorkout(modelContext: ModelContext) {
        if let active = activeWorkout {
            modelContext.delete(active)
            try? modelContext.save()
        }
        stopDurationTimer()
        activeWorkout = nil
        elapsedTime = 0
    }

    public func finishWorkout(modelContext: ModelContext) {
        guard let workout = activeWorkout else { return }
        workout.endDate = Date()
        try? modelContext.save()

        // Sauvegarder dans HealthKit si activé
        HealthKitManager.shared.saveWorkout(startDate: workout.startDate, endDate: workout.endDate!)

        newlyCompletedWorkout = workout
        showSummarySheet = true

        stopDurationTimer()
        activeWorkout = nil
        elapsedTime = 0
    }

    private func startDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let active = self.activeWorkout else { return }
            self.elapsedTime = Date().timeIntervalSince(active.startDate)
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}
