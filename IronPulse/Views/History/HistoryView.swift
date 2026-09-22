import SwiftUI
import SwiftData

public struct HistoryView: View {
    @Query(sort: \Workout.startDate, order: .reverse) private var allWorkouts: [Workout]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText: String = ""

    private var completedWorkouts: [Workout] {
        allWorkouts.filter { $0.isCompleted }
    }

    private var filteredWorkouts: [Workout] {
        if searchText.isEmpty {
            return completedWorkouts
        }
        return completedWorkouts.filter { w in
            let matchesName = (w.routineName ?? "").localizedCaseInsensitiveContains(searchText)
            let matchesExercise = w.exercises.contains { $0.exerciseName.localizedCaseInsensitiveContains(searchText) }
            return matchesName || matchesExercise
        }
    }

    public var body: some View {
        NavigationStack {
            Group {
                if completedWorkouts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Aucune séance dans l'historique")
                            .font(.headline)
                        Text("Vos séances terminées apparaîtront ici avec le détail de vos performances.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredWorkouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutRowCard(workout: workout)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .destructive) {
                                Button(role: .destructive) {
                                    modelContext.delete(workout)
                                    try? modelContext.save()
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Rechercher une séance ou un exercice...")
                }
            }
            .navigationTitle("Historique")
        }
    }
}

// MARK: - Carte de rangée d'historique
struct WorkoutRowCard: View {
    let workout: Workout

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(workout.routineName ?? "Séance d'entraînement")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.primary)

                    Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if let feeling = workout.feeling {
                    Text(feelingEmoji(feeling))
                        .font(.title3)
                }
            }

            // Tags des muscles sollicités
            let muscles = workout.muscleGroupsWorked
            if !muscles.isEmpty {
                HStack(spacing: 6) {
                    ForEach(muscles.prefix(4), id: \.self) { m in
                        Text(m.displayName)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(m.color.opacity(0.15))
                            .foregroundColor(m.color)
                            .cornerRadius(4)
                    }
                    if muscles.count > 4 {
                        Text("+\(muscles.count - 4)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // Métriques clés
            HStack(spacing: 16) {
                Label(workout.durationFormatted, systemImage: "clock")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Label("\(workout.totalSetsCompleted) séries", systemImage: "checkmark.circle")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)

                Spacer()

                let volText = workout.totalVolume >= 1000 ? String(format: "%.1f tonnes", workout.totalVolume / 1000) : String(format: "%.0f kg", workout.totalVolume)
                Text(volText)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.orange)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(14)
    }

    private func feelingEmoji(_ feeling: Int) -> String {
        switch feeling {
        case 5: return "🔥"
        case 4: return "💪"
        case 3: return "🙂"
        case 2: return "😕"
        case 1: return "😫"
        default: return "💪"
        }
    }
}
