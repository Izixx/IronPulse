import SwiftUI
import SwiftData

public struct AddExerciseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedMuscles: Set<MuscleGroup> = []
    @State private var selectedEquipment: String = "Barre"
    @State private var selectedCategory: String = "Polyarticulaire"
    @State private var notes: String = ""
    @State private var showAlert: Bool = false

    private let equipments = ["Barre", "Haltères", "Poulie", "Machine", "Poids du corps", "Élastique"]
    private let categories = ["Polyarticulaire", "Isolation"]

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations de l'exercice")) {
                    TextField("Nom de l'exercice (ex: Hack Squat)", text: $name)

                    Picker("Équipement", selection: $selectedEquipment) {
                        ForEach(equipments, id: \.self) { eq in
                            Text(eq).tag(eq)
                        }
                    }

                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }

                Section(header: Text("Groupes musculaires ciblés")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(MuscleGroup.allCases) { muscle in
                            let isSelected = selectedMuscles.contains(muscle)
                            Button(action: {
                                if isSelected {
                                    selectedMuscles.remove(muscle)
                                } else {
                                    selectedMuscles.insert(muscle)
                                }
                            }) {
                                HStack {
                                    Image(systemName: muscle.sfSymbol)
                                    Text(muscle.displayName)
                                        .font(.subheadline)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.caption.weight(.bold))
                                    }
                                }
                                .padding(10)
                                .background(isSelected ? muscle.color.opacity(0.2) : Color(uiColor: .tertiarySystemBackground))
                                .foregroundColor(isSelected ? muscle.color : .primary)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Notes ou consignes d'exécution")) {
                    TextField("Optionnel : position des pieds, tempo, repères...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Nouvel exercice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        saveExercise()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || selectedMuscles.isEmpty)
                }
            }
            .alert("Informations incomplètes", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Veuillez renseigner un nom et sélectionner au moins un groupe musculaire.")
            }
        }
    }

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !selectedMuscles.isEmpty else {
            showAlert = true
            return
        }

        let newExercise = Exercise(
            name: trimmedName,
            muscleGroups: Array(selectedMuscles),
            equipment: selectedEquipment,
            category: selectedCategory,
            isCustom: true,
            notes: notes
        )

        modelContext.insert(newExercise)
        try? modelContext.save()
        dismiss()
    }
}
