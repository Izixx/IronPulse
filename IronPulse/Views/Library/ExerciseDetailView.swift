import SwiftUI
import Charts
import SwiftData

public struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @Query(sort: \Workout.startDate, order: .reverse) private var allWorkouts: [Workout]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirmation = false

    private var completedWorkouts: [Workout] {
        allWorkouts.filter { $0.isCompleted }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // En-tête : Badges
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(exercise.muscleGroups, id: \.self) { m in
                            Label(m.displayName, systemImage: m.sfSymbol)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(m.color.opacity(0.18))
                                .foregroundColor(m.color)
                                .cornerRadius(8)
                        }
                    }

                    HStack(spacing: 12) {
                        Text(exercise.equipment)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(6)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(exercise.category)
                            .font(.subheadline)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(6)
                    }

                    if !exercise.notes.isEmpty {
                        Text(exercise.notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 8)

                // Calcul des records et historique
                let (history, records) = StatisticsEngine.computeExerciseProgression(
                    exerciseName: exercise.name,
                    from: completedWorkouts
                )

                // Cartes de Records Personnels
                HStack(spacing: 10) {
                    PRCard(
                        title: "Charge Max",
                        value: records.maxWeight > 0 ? "\(String(format: "%.1f", records.maxWeight)) kg" : "-",
                        icon: "trophy.fill",
                        color: .orange
                    )

                    PRCard(
                        title: "1RM Estimé",
                        value: records.best1RM > 0 ? "\(String(format: "%.1f", records.best1RM)) kg" : "-",
                        icon: "bolt.fill",
                        color: .yellow
                    )

                    PRCard(
                        title: "Meilleur Volume",
                        value: records.bestVolume > 0 ? "\(String(format: "%.0f", records.bestVolume)) kg" : "-",
                        icon: "scalemass.fill",
                        color: .green
                    )
                }

                // Graphique d'évolution
                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Évolution de la charge max")
                            .font(.headline.weight(.bold))

                        Chart(history) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Charge", item.maxWeight)
                            )
                            .foregroundStyle(Color.orange)
                            .lineStyle(StrokeStyle(lineWidth: 3))

                            PointMark(
                                x: .value("Date", item.date),
                                y: .value("Charge", item.maxWeight)
                            )
                            .foregroundStyle(Color.orange)
                            .symbolSize(36)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 180)
                    }
                    .padding(16)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                }

                // Historique des séances où cet exercice a été fait
                VStack(alignment: .leading, spacing: 12) {
                    Text("Historique des performances (\(records.totalTimesPerformed))")
                        .font(.headline.weight(.bold))

                    if history.isEmpty {
                        Text("Aucune séance passée enregistrée pour cet exercice.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(history.reversed()) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.weight(.semibold))
                                    Text("Volume : \(String(format: "%.0f", entry.totalVolume)) kg")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Max : \(String(format: "%.1f", entry.maxWeight)) kg")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.orange)
                                    Text("1RM : \(String(format: "%.1f", entry.bestEstimated1RM)) kg")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                        }
                    }
                }

                // Bouton supprimer si exercice personnalisé
                if exercise.isCustom {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Supprimer cet exercice", systemImage: "trash")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.red)
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .alert("Supprimer cet exercice ?", isPresented: $showingDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                modelContext.delete(exercise)
                try? modelContext.save()
                dismiss()
            }
        } message: {
            Text("Cet exercice personnalisé sera retiré de votre bibliothèque.")
        }
    }
}
