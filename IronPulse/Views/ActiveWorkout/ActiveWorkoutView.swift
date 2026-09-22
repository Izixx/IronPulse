import SwiftUI
import SwiftData

public struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState = AppState.shared
    @Query(sort: \Workout.startDate, order: .reverse) private var pastWorkouts: [Workout]
    @Query(filter: #Predicate<Routine> { $0.isActive }) private var activeRoutines: [Routine]

    @State private var showingExercisePicker = false
    @State private var showingCancelConfirmation = false
    @State private var showingFinishConfirmation = false

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                if let workout = appState.activeWorkout {
                    // SEANCE EN COURS
                    ScrollView {
                        VStack(spacing: 16) {
                            // En-tête de la séance active (Nom + Chronomètre)
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(workout.routineName ?? "Séance d'entraînement")
                                        .font(.title2.weight(.bold))
                                    
                                    HStack(spacing: 8) {
                                        Label(appState.elapsedTimeFormatted, systemImage: "timer")
                                            .font(.subheadline.weight(.semibold).monospacedDigit())
                                            .foregroundColor(.orange)

                                        Text("•")
                                            .foregroundColor(.secondary)

                                        Text("\(workout.totalSetsCompleted) séries faites")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Button(action: { showingFinishConfirmation = true }) {
                                    Text("Terminer")
                                        .font(.subheadline.weight(.bold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.green)
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Liste des cartes d'exercices
                            ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { workoutExercise in
                                WorkoutExerciseCard(
                                    workoutExercise: workoutExercise,
                                    previousSetsHint: findPreviousSets(for: workoutExercise.exerciseName),
                                    onDeleteExercise: {
                                        deleteExercise(workoutExercise)
                                    }
                                )
                            }
                            .padding(.horizontal, 16)

                            // Bouton Ajouter un Exercice
                            BigActionButton(
                                title: "Ajouter un exercice",
                                systemImage: "plus.circle.fill",
                                style: .secondary
                            ) {
                                showingExercisePicker = true
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                            // Bouton Abandonner / Annuler la séance
                            Button(action: { showingCancelConfirmation = true }) {
                                Text("Abandonner la séance")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.red)
                                    .padding(.vertical, 12)
                            }
                            .padding(.bottom, 60)
                        }
                    }

                    // Minuteur de repos flottant en haut
                    RestTimerOverlay()
                        .padding(.top, 8)

                } else {
                    // AUCUNE SEANCE EN COURS -> DASHBOARD DE DEMARRAGE
                    ScrollView {
                        VStack(spacing: 24) {
                            // En-tête accrocheur
                            VStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.system(size: 60))
                                    .foregroundColor(.orange)
                                    .padding(.top, 30)

                                Text("Prêt à soulever ?")
                                    .font(.title.weight(.bold))

                                Text("Démarrez une nouvelle séance ou reprenez votre cycle d'entraînement.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }

                            // 1. Bouton : Séance suggérée de la routine active (si configurée)
                            if let routine = activeRoutines.first, let nextDay = routine.currentDay {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("PROGRAMME ACTIF")
                                            .font(.caption2.weight(.bold))
                                            .foregroundColor(.orange)
                                        Spacer()
                                        Text(routine.name)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(nextDay.name)
                                            .font(.headline.weight(.bold))

                                        HStack(spacing: 6) {
                                            ForEach(nextDay.muscleGroups, id: \.self) { m in
                                                Text(m.displayName)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(m.color.opacity(0.15))
                                                    .foregroundColor(m.color)
                                                    .cornerRadius(4)
                                            }
                                        }

                                        Text("\(nextDay.exerciseNames.count) exercices prévus")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.top, 2)
                                    }
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(14)

                                    BigActionButton(
                                        title: "Démarrer \(nextDay.name)",
                                        systemImage: "play.fill",
                                        style: .primary
                                    ) {
                                        appState.startWorkout(routine: routine, routineDay: nextDay, modelContext: modelContext)
                                        routine.advanceCycle()
                                        try? modelContext.save()
                                    }
                                }
                                .padding(.horizontal, 16)
                            }

                            // 2. Bouton : Nouvelle séance libre
                            VStack(alignment: .leading, spacing: 10) {
                                BigActionButton(
                                    title: "Démarrer une séance libre",
                                    systemImage: "bolt.fill",
                                    style: activeRoutines.isEmpty ? .primary : .secondary
                                ) {
                                    appState.startWorkout(modelContext: modelContext)
                                }
                            }
                            .padding(.horizontal, 16)

                            // 3. Bouton : Dupliquer la dernière séance
                            if let lastWorkout = pastWorkouts.first(where: { $0.isCompleted }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("RÉPÉTER LA DERNIÈRE FOIS")
                                            .font(.caption2.weight(.bold))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text(lastWorkout.startDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Button(action: {
                                        appState.duplicateWorkout(lastWorkout, modelContext: modelContext)
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(lastWorkout.routineName ?? "Séance précédente")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)

                                                Text("\(lastWorkout.exercises.count) exercices • \(lastWorkout.totalSetsCompleted) séries • \(String(format: "%.0f", lastWorkout.totalVolume)) kg")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }

                                            Spacer()

                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .font(.title3)
                                                .foregroundColor(.orange)
                                        }
                                        .padding(14)
                                        .background(Color(uiColor: .secondarySystemBackground))
                                        .cornerRadius(14)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .navigationTitle(appState.isWorkoutActive ? "Séance en cours" : "Entraînement")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerSheet { selectedExercise in
                    addExerciseToActiveWorkout(selectedExercise)
                }
            }
            .sheet(isPresented: $appState.showSummarySheet) {
                if let completed = appState.newlyCompletedWorkout {
                    WorkoutSummarySheet(workout: completed)
                }
            }
            .alert("Abandonner la séance ?", isPresented: $showingCancelConfirmation) {
                Button("Continuer la séance", role: .cancel) {}
                Button("Abandonner et effacer", role: .destructive) {
                    appState.cancelWorkout(modelContext: modelContext)
                }
            } message: {
                Text("Toutes les séries enregistrées pour cette séance seront perdues.")
            }
            .alert("Terminer la séance ?", isPresented: $showingFinishConfirmation) {
                Button("Pas encore", role: .cancel) {}
                Button("Oui, terminer", role: .none) {
                    appState.finishWorkout(modelContext: modelContext)
                }
            } message: {
                Text("Validez votre séance pour enregistrer vos statistiques et records !")
            }
        }
    }

    private func addExerciseToActiveWorkout(_ exercise: Exercise) {
        guard let workout = appState.activeWorkout else { return }

        // Vérifier s'il y a des séries antérieures pour préremplir
        let previous = findPreviousSets(for: exercise.name)
        let initialSets: [ExerciseSet]

        if let prev = previous, !prev.isEmpty {
            initialSets = prev.enumerated().map { i, s in
                ExerciseSet(setNumber: i + 1, reps: s.reps, weightKg: s.weightKg, rpe: nil, isCompleted: false, isWarmup: s.isWarmup)
            }
        } else {
            initialSets = [
                ExerciseSet(setNumber: 1, reps: 10, weightKg: 0, rpe: nil, isCompleted: false, isWarmup: false),
                ExerciseSet(setNumber: 2, reps: 10, weightKg: 0, rpe: nil, isCompleted: false, isWarmup: false),
                ExerciseSet(setNumber: 3, reps: 10, weightKg: 0, rpe: nil, isCompleted: false, isWarmup: false)
            ]
        }

        let newOrder = workout.exercises.count
        let workoutExercise = WorkoutExercise(
            order: newOrder,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            muscleGroups: exercise.muscleGroups,
            notes: "",
            sets: initialSets
        )

        workout.exercises.append(workoutExercise)
        try? modelContext.save()
    }

    private func deleteExercise(_ we: WorkoutExercise) {
        guard let workout = appState.activeWorkout else { return }
        workout.exercises.removeAll { $0.id == we.id }
        modelContext.delete(we)
        try? modelContext.save()
    }

    private func findPreviousSets(for exerciseName: String) -> [ExerciseSet]? {
        for w in pastWorkouts where w.isCompleted && w.id != appState.activeWorkout?.id {
            if let we = w.exercises.first(where: { $0.exerciseName.caseInsensitiveCompare(exerciseName) == .orderedSame }) {
                let completed = we.completedSets
                if !completed.isEmpty {
                    return completed
                }
            }
        }
        return nil
    }
}
