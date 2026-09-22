import SwiftUI
import SwiftData

@main
struct IronPulseApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Workout.self,
                WorkoutExercise.self,
                ExerciseSet.self,
                Exercise.self,
                Routine.self,
                RoutineDay.self,
                BodyWeightEntry.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Erreur d'initialisation SwiftData: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark) // Mode sombre optimal pour la salle
        }
        .modelContainer(container)
    }
}
