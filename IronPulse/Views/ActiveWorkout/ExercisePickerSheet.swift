import SwiftUI
import SwiftData

public struct ExercisePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    public let onSelect: (Exercise) -> Void

    @State private var searchText: String = ""
    @State private var selectedMuscle: MuscleGroup? = nil

    private var filteredExercises: [Exercise] {
        allExercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscle == nil || ex.muscleGroups.contains(selectedMuscle!)
            return matchesSearch && matchesMuscle
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filtre horizontal des muscles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { selectedMuscle = nil }) {
                            Text("Tous")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedMuscle == nil ? Color.orange : Color(uiColor: .secondarySystemBackground))
                                .foregroundColor(selectedMuscle == nil ? .black : .primary)
                                .cornerRadius(20)
                        }

                        ForEach(MuscleGroup.allCases) { muscle in
                            Button(action: {
                                if selectedMuscle == muscle {
                                    selectedMuscle = nil
                                } else {
                                    selectedMuscle = muscle
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: muscle.sfSymbol)
                                        .font(.caption2)
                                    Text(muscle.displayName)
                                }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedMuscle == muscle ? muscle.color : Color(uiColor: .secondarySystemBackground))
                                .foregroundColor(selectedMuscle == muscle ? .black : .primary)
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                // Liste des exercices filtrés
                List(filteredExercises) { exercise in
                    Button(action: {
                        onSelect(exercise)
                        dismiss()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exercise.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                HStack(spacing: 6) {
                                    Text(exercise.equipment)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.gray.opacity(0.15))
                                        .cornerRadius(4)

                                    ForEach(exercise.muscleGroups, id: \.self) { m in
                                        Text(m.displayName)
                                            .font(.caption2)
                                            .foregroundColor(m.color)
                                    }
                                }
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .searchable(text: $searchText, prompt: "Rechercher un exercice...")
            }
            .navigationTitle("Ajouter un exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}
