import SwiftUI

public struct MuscleRecoveryView: View {
    public let readinessItems: [MuscleReadinessItem]

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Quoi entraîner aujourd'hui ?")
                        .font(.headline.weight(.bold))
                    Text("Basé sur une récupération optimale de 48-72h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "figure.cross-training")
                    .foregroundColor(.orange)
            }

            // Bannière de recommandation immédiate
            let recommended = readinessItems.filter { $0.status == .priority || $0.status == .ready }
            if !recommended.isEmpty {
                let muscleNames = recommended.prefix(3).map { $0.muscle.displayName }.joined(by: ", ")
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recommandé pour votre séance")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.orange)
                        Text(muscleNames)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(12)
            }

            // Grille des 10 groupes musculaires
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(readinessItems) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.status.sfIcon)
                            .font(.headline)
                            .foregroundColor(item.status.badgeColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.muscle.displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)

                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(10)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
