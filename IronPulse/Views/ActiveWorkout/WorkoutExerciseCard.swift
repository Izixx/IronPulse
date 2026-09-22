import SwiftUI
import SwiftData

public struct WorkoutExerciseCard: View {
    @Bindable var workoutExercise: WorkoutExercise
    public let previousSetsHint: [ExerciseSet]?
    public let onDeleteExercise: () -> Void

    @State private var showingRPEPickerForSet: ExerciseSet? = nil

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // En-tête de la carte
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workoutExercise.exerciseName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        ForEach(workoutExercise.muscleGroups, id: \.self) { muscle in
                            Text(muscle.displayName)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(muscle.color.opacity(0.18))
                                .foregroundColor(muscle.color)
                                .cornerRadius(6)
                        }
                    }
                }

                Spacer()

                Menu {
                    if let prev = previousSetsHint, !prev.isEmpty {
                        Button(action: copyPreviousValues) {
                            Label("Recopier dernière séance", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }

                    Button(role: .destructive, action: onDeleteExercise) {
                        Label("Supprimer l'exercice", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                }
            }

            // Indication de la dernière performance si disponible
            if let prev = previousSetsHint, !prev.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                        .foregroundColor(.orange)

                    let summary = prev.map { "\($0.reps)×\($0.weightKg > 0 ? String(format: "%.1f", $0.weightKg) : "0")kg" }.joined(by: ", ")
                    Text("Dernière fois: \(summary)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer()

                    Button(action: copyPreviousValues) {
                        Text("Recopier")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(8)
            }

            // En-tête du tableau des séries
            HStack(spacing: 8) {
                Text("SÉRIE")
                    .frame(width: 44, alignment: .center)
                Text("REPS")
                    .frame(width: 60, alignment: .center)
                Text("KG")
                    .frame(width: 70, alignment: .center)
                Text("RPE")
                    .frame(width: 50, alignment: .center)
                Spacer()
                Text("STATUT")
                    .frame(width: 44, alignment: .center)
            }
            .font(.caption2.weight(.bold))
            .foregroundColor(.secondary)

            // Lignes de séries
            VStack(spacing: 8) {
                ForEach(Array(workoutExercise.sets.enumerated()), id: \.element.id) { index, set in
                    SetRowView(
                        setIndex: index + 1,
                        exerciseSet: set,
                        previousSet: previousSetsHint != nil && index < previousSetsHint!.count ? previousSetsHint![index] : nil,
                        exerciseName: workoutExercise.exerciseName,
                        onOpenRPE: {
                            showingRPEPickerForSet = set
                        },
                        onDeleteSet: {
                            deleteSet(at: index)
                        }
                    )
                }
            }

            // Bouton Ajouter une Série
            Button(action: addSet) {
                HStack {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                    Text("Ajouter une série")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Color(uiColor: .tertiarySystemBackground))
                .foregroundColor(.orange)
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .sheet(item: $showingRPEPickerForSet) { set in
            RPEPickerView(selectedRPE: Binding(
                get: { set.rpe },
                set: { set.rpe = $0 }
            ))
        }
    }

    private func addSet() {
        let lastSet = workoutExercise.sets.last
        let nextNumber = (lastSet?.setNumber ?? 0) + 1
        let defaultReps = lastSet?.reps ?? 10
        let defaultWeight = lastSet?.weightKg ?? 0.0

        let newSet = ExerciseSet(
            setNumber: nextNumber,
            reps: defaultReps,
            weightKg: defaultWeight,
            rpe: nil,
            isCompleted: false,
            isWarmup: false
        )
        workoutExercise.sets.append(newSet)

        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func deleteSet(at index: Int) {
        guard workoutExercise.sets.indices.contains(index) else { return }
        workoutExercise.sets.remove(at: index)
        // Réindexer
        for (i, s) in workoutExercise.sets.enumerated() {
            s.setNumber = i + 1
        }
    }

    private func copyPreviousValues() {
        guard let prev = previousSetsHint, !prev.isEmpty else { return }
        workoutExercise.sets.removeAll()

        for (i, s) in prev.enumerated() {
            let newSet = ExerciseSet(
                setNumber: i + 1,
                reps: s.reps,
                weightKg: s.weightKg,
                rpe: s.rpe,
                isCompleted: false,
                isWarmup: s.isWarmup
            )
            workoutExercise.sets.append(newSet)
        }

        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

// MARK: - Ligne de série individuelle
struct SetRowView: View {
    let setIndex: Int
    @Bindable var exerciseSet: ExerciseSet
    let previousSet: ExerciseSet?
    let exerciseName: String
    let onOpenRPE: () -> Void
    let onDeleteSet: () -> Void

    @FocusState private var isRepsFocused: Bool
    @FocusState private var isWeightFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Numéro de série
            Text("\(setIndex)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(exerciseSet.isCompleted ? .secondary : .primary)
                .frame(width: 44, alignment: .center)

            // Répétitions
            TextField(
                previousSet != nil ? "\(previousSet!.reps)" : "10",
                value: $exerciseSet.reps,
                format: .number
            )
            .keyboardType(.numberPad)
            .focused($isRepsFocused)
            .multilineTextAlignment(.center)
            .font(.subheadline.weight(.semibold))
            .frame(width: 60, height: 38)
            .background(exerciseSet.isCompleted ? Color(uiColor: .tertiarySystemFill).opacity(0.5) : Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)

            // Poids en kg
            TextField(
                previousSet != nil ? String(format: "%.1f", previousSet!.weightKg) : "0",
                value: $exerciseSet.weightKg,
                format: .number
            )
            .keyboardType(.decimalPad)
            .focused($isWeightFocused)
            .multilineTextAlignment(.center)
            .font(.subheadline.weight(.semibold))
            .frame(width: 70, height: 38)
            .background(exerciseSet.isCompleted ? Color(uiColor: .tertiarySystemFill).opacity(0.5) : Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)

            // Bouton RPE
            Button(action: onOpenRPE) {
                Text(exerciseSet.rpe != nil ? String(format: "%.1f", exerciseSet.rpe!) : "-")
                    .font(.caption.weight(.bold))
                    .foregroundColor(exerciseSet.rpe != nil ? .orange : .secondary)
                    .frame(width: 50, height: 38)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(8)
            }

            Spacer()

            // Bouton de validation géant (Vert si validé)
            Button(action: toggleCompletion) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(exerciseSet.isCompleted ? Color.green : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 38)

                    Image(systemName: exerciseSet.isCompleted ? "checkmark" : "checkmark")
                        .font(.body.weight(.bold))
                        .foregroundColor(exerciseSet.isCompleted ? .black : .secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button(role: .destructive, action: onDeleteSet) {
                Label("Supprimer cette série", systemImage: "trash")
            }
        }
    }

    private func toggleCompletion() {
        exerciseSet.isCompleted.toggle()

        if exerciseSet.isCompleted {
            exerciseSet.completedAt = Date()
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()

            // Démarrer automatiquement le minuteur de repos (90s par défaut)
            RestTimerViewModel.shared.start(duration: 90, exercise: exerciseName)
        } else {
            exerciseSet.completedAt = nil
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
}
