import SwiftUI
import SwiftData

public enum LibrarySection: String, CaseIterable, Identifiable {
    case exercises = "Exercices"
    case routines = "Programmes"

    public var id: String { rawValue }
}

public struct ExerciseLibraryView: View {
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var selectedSection: LibrarySection = .exercises
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var searchText: String = ""
    @State private var showingAddExerciseSheet = false

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
                // Sélecteur de section : Exercices vs Programmes
                Picker("Section", selection: $selectedSection) {
                    ForEach(LibrarySection.allCases) { section in
                        Text(section.rawValue).tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                if selectedSection == .exercises {
                    // SECTION EXERCICES
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
                            .padding(.vertical, 6)
                        }

                        // Liste des exercices
                        List(filteredExercises) { exercise in
                            NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 6) {
                                            Text(exercise.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)

                                            if exercise.isCustom {
                                                Text("Perso")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.15))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(4)
                                            }
                                        }

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
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .listStyle(.plain)
                        .searchable(text: $searchText, prompt: "Rechercher parmi les exercices...")
                    }
                } else {
                    // SECTION PROGRAMMES & ROUTINES
                    RoutinesView()
                }
            }
            .navigationTitle("Bibliothèque")
            .toolbar {
                if selectedSection == .exercises {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddExerciseSheet = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddExerciseSheet) {
                AddExerciseSheet()
            }
        }
    }
}
