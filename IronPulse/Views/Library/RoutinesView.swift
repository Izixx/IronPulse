import SwiftUI
import SwiftData

public struct RoutinesView: View {
    @Query private var routines: [Routine]
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState = AppState.shared

    @State private var showingCreateRoutineSheet = false

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if routines.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.clipboard")
                            .font(.system(size: 54))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Aucune routine configurée")
                            .font(.headline)
                        Text("Créez des programmes réutilisables (PPL, Upper/Lower...) pour structurer vos séances.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(routines) { routine in
                        RoutineCardView(routine: routine)
                    }
                }

                // Bouton Créer une Routine
                BigActionButton(
                    title: "Créer un programme",
                    systemImage: "plus.circle.fill",
                    style: .secondary
                ) {
                    showingCreateRoutineSheet = true
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .sheet(isPresented: $showingCreateRoutineSheet) {
            CreateRoutineSheet()
        }
    }
}

// MARK: - Carte d'une Routine
struct RoutineCardView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var modelContext
    @Bindable var appState = AppState.shared
    @Query private var allRoutines: [Routine]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // En-tête de la routine
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(routine.name)
                            .font(.headline.weight(.bold))

                        if routine.isActive {
                            Text("ACTIF")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(6)
                        }
                    }

                    if !routine.details.isEmpty {
                        Text(routine.details)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Menu {
                    Button(action: toggleActiveRoutine) {
                        Label(routine.isActive ? "Désactiver le programme" : "Définir comme programme actif", systemImage: routine.isActive ? "pause.circle" : "checkmark.circle")
                    }

                    Button(role: .destructive, action: deleteRoutine) {
                        Label("Supprimer le programme", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            // Liste des jours du cycle
            VStack(spacing: 8) {
                ForEach(routine.sortedDays) { day in
                    let isNext = routine.isActive && routine.currentDay?.id == day.id
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(isNext ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(day.name)
                                    .font(.subheadline.weight(isNext ? .bold : .semibold))
                                    .foregroundColor(isNext ? .primary : .secondary)

                                if isNext {
                                    Text("Séance suivante")
                                        .font(.caption2.weight(.bold))
                                        .foregroundColor(.orange)
                                }
                            }

                            Text(day.exerciseNames.joined(separator: " • "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Button(action: {
                            appState.startWorkout(routine: routine, routineDay: day, modelContext: modelContext)
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(10)
                    .background(isNext ? Color.orange.opacity(0.08) : Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(10)
                }
            }

            // Bouton Démarrer la séance suggérée du cycle
            if routine.isActive, let currentDay = routine.currentDay {
                Button(action: {
                    appState.startWorkout(routine: routine, routineDay: currentDay, modelContext: modelContext)
                    routine.advanceCycle()
                    try? modelContext.save()
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Démarrer : \(currentDay.name)")
                    }
                    .font(.subheadline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.orange)
                    .foregroundColor(.black)
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
    }

    private func toggleActiveRoutine() {
        if routine.isActive {
            routine.isActive = false
        } else {
            // Désactiver les autres routines
            for r in allRoutines {
                r.isActive = false
            }
            routine.isActive = true
        }
        try? modelContext.save()
    }

    private func deleteRoutine() {
        modelContext.delete(routine)
        try? modelContext.save()
    }
}

// MARK: - Feuille de création d'une routine
struct CreateRoutineSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var routineName: String = ""
    @State private var routineDescription: String = ""
    @State private var day1Name: String = "Jour 1"
    @State private var day2Name: String = "Jour 2"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Informations du programme")) {
                    TextField("Nom (ex: Push Pull Legs 4j)", text: $routineName)
                    TextField("Description ou objectif (optionnel)", text: $routineDescription)
                }

                Section(header: Text("Jours d'entraînement")) {
                    TextField("Nom séance 1 (ex: Haut du corps)", text: $day1Name)
                    TextField("Nom séance 2 (ex: Bas du corps)", text: $day2Name)
                }
            }
            .navigationTitle("Nouveau programme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        let newRoutine = Routine(
                            name: routineName.trimmingCharacters(in: .whitespaces),
                            details: routineDescription,
                            isActive: false,
                            days: [
                                RoutineDay(dayOrder: 0, name: day1Name, exerciseNames: ["Développé couché (Barre)", "Rowing barre buste penché"]),
                                RoutineDay(dayOrder: 1, name: day2Name, exerciseNames: ["Squat arrière (Back squat)", "Soulevé de terre roumain (RDL)"])
                            ]
                        )
                        modelContext.insert(newRoutine)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(routineName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
