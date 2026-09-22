import SwiftUI
import SwiftData

public struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteAlert = false
    @State private var isEditingNotes = false

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Métriques principales
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: "Durée",
                        value: workout.durationFormatted,
                        icon: "clock.fill",
                        color: .blue
                    )

                    StatCard(
                        title: "Volume total",
                        value: workout.totalVolume >= 1000 ? String(format: "%.1f", workout.totalVolume / 1000) : String(format: "%.0f", workout.totalVolume),
                        unit: workout.totalVolume >= 1000 ? "t" : "kg",
                        icon: "scalemass.fill",
                        color: .orange
                    )

                    StatCard(
                        title: "Séries validées",
                        value: "\(workout.totalSetsCompleted)",
                        unit: "séries",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )

                    StatCard(
                        title: "Répétitions",
                        value: "\(workout.totalRepsCompleted)",
                        unit: "reps",
                        icon: "repeat",
                        color: .purple
                    )
                }

                // Ressenti et Notes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Ressenti :")
                            .font(.subheadline.weight(.semibold))
                        Text(feelingDescription(workout.feeling))
                            .font(.subheadline)
                    }

                    if !workout.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes :")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                            Text(workout.notes)
                                .font(.subheadline)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(10)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(14)

                // Détail des exercices
                VStack(alignment: .leading, spacing: 14) {
                    Text("Exercices réalisés")
                        .font(.headline.weight(.bold))

                    ForEach(workout.exercises.sorted(by: { $0.order < $1.order })) { we in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(we.exerciseName)
                                    .font(.subheadline.weight(.bold))
                                Spacer()
                                Text(String(format: "%.0f kg", we.totalVolume))
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.orange)
                            }

                            // Tableau des séries
                            VStack(spacing: 6) {
                                ForEach(we.sets.sorted(by: { $0.setNumber < $1.setNumber })) { s in
                                    HStack {
                                        Text("Série \(s.setNumber)")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(.secondary)
                                            .frame(width: 60, alignment: .leading)

                                        Text("\(s.reps) reps × \(String(format: "%.1f", s.weightKg)) kg")
                                            .font(.caption)

                                        if let rpe = s.rpe {
                                            Text("@ RPE \(String(format: "%.1f", rpe))")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundColor(.orange)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.orange.opacity(0.12))
                                                .cornerRadius(4)
                                        }

                                        Spacer()

                                        if s.isCompleted {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color(uiColor: .tertiarySystemBackground))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }

                // Bouton Dupliquer
                BigActionButton(
                    title: "Répéter cette séance",
                    systemImage: "arrow.triangle.2.circlepath",
                    style: .primary
                ) {
                    AppState.shared.duplicateWorkout(workout, modelContext: modelContext)
                    dismiss()
                }

                // Bouton Supprimer
                Button(role: .destructive, action: { showingDeleteAlert = true }) {
                    Label("Supprimer cette séance", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.red)
                        .padding(.vertical, 12)
                }
            }
            .padding(16)
        }
        .navigationTitle(workout.routineName ?? workout.startDate.formatted(date: .abbreviated, time: .shortened))
        .navigationBarTitleDisplayMode(.inline)
        .alert("Supprimer la séance ?", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                modelContext.delete(workout)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("Cette action supprimera définitivement cette séance de votre historique.")
        }
    }

    private func feelingDescription(_ feeling: Int?) -> String {
        switch feeling {
        case 5: return "🔥 Incroyable"
        case 4: return "💪 Très bon"
        case 3: return "🙂 Correct"
        case 2: return "😕 Difficile"
        case 1: return "😫 Épuisé"
        default: return "Non renseigné"
        }
    }
}
