import SwiftUI
import SwiftData

public struct WorkoutSummarySheet: View {
    public let workout: Workout
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var notesText: String = ""
    @State private var selectedFeeling: Int = 4

    private let feelings: [(rating: Int, emoji: String, title: String)] = [
        (1, "😫", "Épuisé"),
        (2, "😕", "Difficile"),
        (3, "🙂", "Correct"),
        (4, "💪", "Très bon"),
        (5, "🔥", "Incroyable")
    ]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Célébration
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 5)

                        Text("Séance Terminée !")
                            .font(.title.weight(.bold))

                        Text(workout.routineName ?? "Entraînement")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)

                    // Statistiques de la séance
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
                            unit: workout.totalVolume >= 1000 ? "tonnes" : "kg",
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

                    // Ressenti de la séance
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ressenti de la séance")
                            .font(.headline)

                        HStack(spacing: 12) {
                            ForEach(feelings, id: \.rating) { f in
                                Button(action: {
                                    selectedFeeling = f.rating
                                    let impact = UIImpactFeedbackGenerator(style: .light)
                                    impact.impactOccurred()
                                }) {
                                    VStack(spacing: 4) {
                                        Text(f.emoji)
                                            .font(.title2)
                                        Text(f.title)
                                            .font(.caption2)
                                            .foregroundColor(selectedFeeling == f.rating ? .orange : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedFeeling == f.rating ? Color.orange.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedFeeling == f.rating ? Color.orange : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Notes de séance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes personnelles")
                            .font(.headline)

                        TextField("Ex: Excellente congestion sur le développé, penser à augmenter la charge la prochaine fois...", text: $notesText, axis: .vertical)
                            .lineLimit(3...5)
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    // Bouton Enregistrer & Fermer
                    BigActionButton(
                        title: "Enregistrer & Fermer",
                        systemImage: "checkmark.circle.fill",
                        style: .primary
                    ) {
                        workout.feeling = selectedFeeling
                        workout.notes = notesText
                        try? modelContext.save()
                        dismiss()
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        workout.feeling = selectedFeeling
                        workout.notes = notesText
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                notesText = workout.notes
                selectedFeeling = workout.feeling ?? 4
            }
        }
    }
}
