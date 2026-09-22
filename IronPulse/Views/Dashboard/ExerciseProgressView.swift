import SwiftUI
import Charts
import SwiftData

public enum ProgressMetric: String, CaseIterable, Identifiable {
    case maxWeight = "Charge max"
    case estimated1RM = "1RM estimé"
    case volume = "Volume total"

    public var id: String { rawValue }
}

public struct ExerciseProgressView: View {
    public let workouts: [Workout]
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var selectedExerciseName: String = "Développé couché (Barre)"
    @State private var selectedMetric: ProgressMetric = .maxWeight

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Progression par exercice")
                        .font(.headline.weight(.bold))
                    Text("Évolution des charges et records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // Menu de sélection de l'exercice
                Menu {
                    ForEach(allExercises) { ex in
                        Button(ex.name) {
                            selectedExerciseName = ex.name
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedExerciseName)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(8)
                }
            }

            // Calcul des données pour l'exercice sélectionné
            let (history, records) = StatisticsEngine.computeExerciseProgression(
                exerciseName: selectedExerciseName,
                from: workouts
            )

            // Cartes de Records Personnels (PR)
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

            // Sélecteur de métrique
            Picker("Métrique", selection: $selectedMetric) {
                ForEach(ProgressMetric.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            // Graphique Swift Charts
            if history.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Aucune donnée enregistrée pour cet exercice")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                Chart(history) { item in
                    let value: Double = {
                        switch selectedMetric {
                        case .maxWeight: return item.maxWeight
                        case .estimated1RM: return item.bestEstimated1RM
                        case .volume: return item.totalVolume
                        }
                    }()

                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value(selectedMetric.rawValue, value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.35), Color.orange.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Date", item.date),
                        y: .value(selectedMetric.rawValue, value)
                    )
                    .foregroundStyle(Color.orange)
                    .lineStyle(StrokeStyle(lineWidth: 3))

                    PointMark(
                        x: .value("Date", item.date),
                        y: .value(selectedMetric.rawValue, value)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(36)
                    .annotation(position: .top) {
                        Text(String(format: "%.0f", value))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
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
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        .onAppear {
            if let first = allExercises.first, selectedExerciseName.isEmpty {
                selectedExerciseName = first.name
            }
        }
    }
}

// MARK: - Carte de Record Personnel (PR)
struct PRCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
    }
}
