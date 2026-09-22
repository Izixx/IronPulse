import SwiftUI
import SwiftData

public struct MainTabView: View {
    @Bindable var appState = AppState.shared
    @Environment(\.modelContext) private var modelContext

    public var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Onglet 1 : Accueil & Stats
            DashboardView()
                .tabItem {
                    Label("Accueil", systemImage: "chart.bar.xaxis")
                }
                .tag(0)

            // Onglet 2 : Séance en cours
            ActiveWorkoutView()
                .tabItem {
                    Label("Séance", systemImage: "figure.strengthtraining.traditional")
                }
                .badge(appState.isWorkoutActive ? "●" : nil)
                .tag(1)

            // Onglet 3 : Historique
            HistoryView()
                .tabItem {
                    Label("Historique", systemImage: "clock.arrow.circlepath")
                }
                .tag(2)

            // Onglet 4 : Bibliothèque & Routines
            ExerciseLibraryView()
                .tabItem {
                    Label("Bibliothèque", systemImage: "dumbbell.fill")
                }
                .tag(3)
        }
        .tint(.orange)
        .onAppear {
            // Initialisation de la base de données avec 35+ exercices lors du 1er lancement
            ExerciseDataSeeder.seedIfNeeded(modelContext: modelContext)
        }
    }
}
