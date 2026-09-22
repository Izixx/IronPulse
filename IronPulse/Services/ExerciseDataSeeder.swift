import Foundation
import SwiftData

public struct ExerciseDataSeeder {
    
    @MainActor
    public static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // 1. Liste des 35 exercices fondamentaux
        let defaultExercises: [Exercise] = [
            // Pectoraux
            Exercise(name: "Développé couché (Barre)", muscleGroups: [.chest, .triceps, .shoulders], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Développé incliné (Haltères)", muscleGroups: [.chest, .shoulders, .triceps], equipment: "Haltères", category: "Polyarticulaire"),
            Exercise(name: "Développé décliné (Barre)", muscleGroups: [.chest, .triceps], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Écarté poulie vis-à-vis", muscleGroups: [.chest], equipment: "Poulie", category: "Isolation"),
            Exercise(name: "Dips (Pectoraux)", muscleGroups: [.chest, .triceps, .shoulders], equipment: "Poids du corps", category: "Polyarticulaire"),
            Exercise(name: "Pompes classiques", muscleGroups: [.chest, .triceps, .shoulders], equipment: "Poids du corps", category: "Polyarticulaire"),

            // Dos
            Exercise(name: "Soulevé de terre (Deadlift)", muscleGroups: [.back, .hamstrings, .glutes], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Tractions pronation", muscleGroups: [.back, .biceps], equipment: "Poids du corps", category: "Polyarticulaire"),
            Exercise(name: "Tractions supination", muscleGroups: [.back, .biceps], equipment: "Poids du corps", category: "Polyarticulaire"),
            Exercise(name: "Rowing barre buste penché", muscleGroups: [.back, .biceps], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Rowing bûcheron haltère", muscleGroups: [.back, .biceps], equipment: "Haltères", category: "Polyarticulaire"),
            Exercise(name: "Tirage vertical poitrine", muscleGroups: [.back, .biceps], equipment: "Poulie", category: "Polyarticulaire"),
            Exercise(name: "Tirage horizontal prise serrée", muscleGroups: [.back, .biceps], equipment: "Poulie", category: "Polyarticulaire"),
            Exercise(name: "Pull-over poulie haute", muscleGroups: [.back], equipment: "Poulie", category: "Isolation"),

            // Épaules
            Exercise(name: "Développé militaire (Overhead press)", muscleGroups: [.shoulders, .triceps], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Développé assis avec haltères", muscleGroups: [.shoulders, .triceps], equipment: "Haltères", category: "Polyarticulaire"),
            Exercise(name: "Élévations latérales haltères", muscleGroups: [.shoulders], equipment: "Haltères", category: "Isolation"),
            Exercise(name: "Élévations latérales à la poulie", muscleGroups: [.shoulders], equipment: "Poulie", category: "Isolation"),
            Exercise(name: "Oiseau haltères (Arrière d'épaule)", muscleGroups: [.shoulders, .back], equipment: "Haltères", category: "Isolation"),
            Exercise(name: "Face pull à la poulie", muscleGroups: [.shoulders, .back], equipment: "Poulie", category: "Isolation"),

            // Biceps
            Exercise(name: "Curl barre EZ", muscleGroups: [.biceps], equipment: "Barre", category: "Isolation"),
            Exercise(name: "Curl incliné aux haltères", muscleGroups: [.biceps], equipment: "Haltères", category: "Isolation"),
            Exercise(name: "Curl marteau (Hammer curl)", muscleGroups: [.biceps], equipment: "Haltères", category: "Isolation"),
            Exercise(name: "Curl pupitre Larry Scott", muscleGroups: [.biceps], equipment: "Machine", category: "Isolation"),

            // Triceps
            Exercise(name: "Barre au front (Skullcrusher)", muscleGroups: [.triceps], equipment: "Barre", category: "Isolation"),
            Exercise(name: "Extension triceps poulie corde", muscleGroups: [.triceps], equipment: "Poulie", category: "Isolation"),
            Exercise(name: "Extension nuque unilatérale haltère", muscleGroups: [.triceps], equipment: "Haltères", category: "Isolation"),
            Exercise(name: "Dips triceps entre deux bancs", muscleGroups: [.triceps], equipment: "Poids du corps", category: "Polyarticulaire"),

            // Quadriceps & Bas du corps
            Exercise(name: "Squat arrière (Back squat)", muscleGroups: [.quadriceps, .glutes], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Front squat", muscleGroups: [.quadriceps, .glutes, .abs], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Presse à cuisses inclinée", muscleGroups: [.quadriceps, .glutes], equipment: "Machine", category: "Polyarticulaire"),
            Exercise(name: "Fentes marchées haltères", muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: "Haltères", category: "Polyarticulaire"),
            Exercise(name: "Leg extension", muscleGroups: [.quadriceps], equipment: "Machine", category: "Isolation"),

            // Ischio-jambiers, Fessiers & Mollets
            Exercise(name: "Soulevé de terre roumain (RDL)", muscleGroups: [.hamstrings, .glutes], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Leg curl couché", muscleGroups: [.hamstrings], equipment: "Machine", category: "Isolation"),
            Exercise(name: "Hip Thrust à la barre", muscleGroups: [.glutes, .hamstrings], equipment: "Barre", category: "Polyarticulaire"),
            Exercise(name: "Mollets debout à la machine", muscleGroups: [.calves], equipment: "Machine", category: "Isolation"),
            Exercise(name: "Mollets assis à la machine", muscleGroups: [.calves], equipment: "Machine", category: "Isolation"),

            // Abdominaux
            Exercise(name: "Crunchs à la poulie haute", muscleGroups: [.abs], equipment: "Poulie", category: "Isolation"),
            Exercise(name: "Relevé de jambes suspendu", muscleGroups: [.abs], equipment: "Poids du corps", category: "Polyarticulaire"),
            Exercise(name: "Gainage planche", muscleGroups: [.abs], equipment: "Poids du corps", category: "Isolation")
        ]

        for exercise in defaultExercises {
            modelContext.insert(exercise)
        }

        // 2. Routines par défaut (PPL, Upper/Lower, Full Body)
        let pplRoutine = Routine(
            name: "Push / Pull / Legs (PPL)",
            details: "Programme 3 jours classique ciblant les mouvements de poussée, de tirage et les jambes.",
            isActive: true,
            currentDayIndex: 0,
            days: [
                RoutineDay(
                    dayOrder: 0,
                    name: "Push A (Pecs / Épaules / Triceps)",
                    muscleGroups: [.chest, .shoulders, .triceps],
                    exerciseNames: [
                        "Développé couché (Barre)",
                        "Développé militaire (Overhead press)",
                        "Développé incliné (Haltères)",
                        "Élévations latérales haltères",
                        "Extension triceps poulie corde"
                    ]
                ),
                RoutineDay(
                    dayOrder: 1,
                    name: "Pull A (Dos / Biceps / Arrière d'épaule)",
                    muscleGroups: [.back, .biceps, .shoulders],
                    exerciseNames: [
                        "Soulevé de terre (Deadlift)",
                        "Tractions pronation",
                        "Rowing barre buste penché",
                        "Face pull à la poulie",
                        "Curl barre EZ"
                    ]
                ),
                RoutineDay(
                    dayOrder: 2,
                    name: "Legs A (Cuisses / Ischios / Mollets / Abdos)",
                    muscleGroups: [.quadriceps, .hamstrings, .glutes, .calves, .abs],
                    exerciseNames: [
                        "Squat arrière (Back squat)",
                        "Presse à cuisses inclinée",
                        "Soulevé de terre roumain (RDL)",
                        "Mollets debout à la machine",
                        "Relevé de jambes suspendu"
                    ]
                )
            ]
        )

        let upperLower = Routine(
            name: "Haut / Bas du Corps (Upper / Lower)",
            details: "Séparation efficace en 2 séances pour un entraînement 4 fois par semaine.",
            isActive: false,
            currentDayIndex: 0,
            days: [
                RoutineDay(
                    dayOrder: 0,
                    name: "Haut du corps (Upper)",
                    muscleGroups: [.chest, .back, .shoulders, .biceps, .triceps],
                    exerciseNames: [
                        "Développé couché (Barre)",
                        "Rowing barre buste penché",
                        "Développé militaire (Overhead press)",
                        "Tirage vertical poitrine",
                        "Barre au front (Skullcrusher)",
                        "Curl incliné aux haltères"
                    ]
                ),
                RoutineDay(
                    dayOrder: 1,
                    name: "Bas du corps (Lower)",
                    muscleGroups: [.quadriceps, .hamstrings, .glutes, .calves, .abs],
                    exerciseNames: [
                        "Squat arrière (Back squat)",
                        "Soulevé de terre roumain (RDL)",
                        "Leg extension",
                        "Mollets assis à la machine",
                        "Crunchs à la poulie haute"
                    ]
                )
            ]
        )

        modelContext.insert(pplRoutine)
        modelContext.insert(upperLower)

        try? modelContext.save()
    }
}
