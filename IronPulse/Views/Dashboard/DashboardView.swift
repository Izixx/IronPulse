import SwiftUI
import SwiftData

public struct DashboardView: View {
    @Query(sort: \Workout.startDate, order: .reverse) private var workouts: [Workout]
    @State private var selectedVolumeFilter: TimeFilter = .last30Days
    @State private var showingSettingsSheet: Bool = false

    private var completedWorkouts: [Workout] {
        workouts.filter { $0.isCompleted }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. Cartes de Statistiques Globales
                    let globalStats = StatisticsEngine.computeGlobalStats(from: completedWorkouts)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Séances totales",
                            value: "\(globalStats.totalWorkouts)",
                            icon: "dumbbell.fill",
                            color: .orange
                        )

                        StatCard(
                            title: "Volume soulevé",
                            value: String(format: "%.1f", globalStats.totalTonnageTonnes),
                            unit: "tonnes",
                            icon: "scalemass.fill",
                            color: .green
                        )

                        StatCard(
                            title: "Séries validées",
                            value: "\(globalStats.totalSets)",
                            icon: "checkmark.circle.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Moyenne hebdo",
                            value: String(format: "%.1f", globalStats.weeklyAverageFrequency),
                            unit: "/ sem",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .purple
                        )
                    }
                    .padding(.horizontal, 16)

                    // 2. « Quoi entraîner aujourd'hui ? »
                    let readiness = StatisticsEngine.computeMuscleReadiness(from: completedWorkouts)
                    MuscleRecoveryView(readinessItems: readiness)
                        .padding(.horizontal, 16)

                    // 3. Volume par Groupe Musculaire (Swift Charts)
                    let volumeItems = StatisticsEngine.computeMuscleVolume(from: completedWorkouts, filter: selectedVolumeFilter)
                    MuscleVolumeChartView(volumeItems: volumeItems, selectedFilter: $selectedVolumeFilter)
                        .padding(.horizontal, 16)

                    // 4. Calendrier d'assiduité (Heatmap)
                    let heatmapDays = StatisticsEngine.computeHeatmap(from: completedWorkouts, weeksCount: 16)
                    HeatmapCalendarView(heatmapDays: heatmapDays)
                        .padding(.horizontal, 16)

                    // 5. Progression et records par exercice
                    ExerciseProgressView(workouts: completedWorkouts)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                }
                .padding(.top, 10)
            }
            .navigationTitle("Tableau de bord")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettingsSheet = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettingsSheet) {
                SettingsView()
            }
        }
    }
}
