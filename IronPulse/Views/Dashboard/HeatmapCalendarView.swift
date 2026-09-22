import SwiftUI

public struct HeatmapCalendarView: View {
    public let heatmapDays: [HeatmapDay]

    private let daySymbols = ["L", "M", "M", "J", "V", "S", "D"]

    // Grouper les jours par colonnes de semaines (7 jours par colonne)
    private var weeks: [[HeatmapDay]] {
        var result: [[HeatmapDay]] = []
        var currentWeek: [HeatmapDay] = []

        for day in heatmapDays {
            currentWeek.append(day)
            if currentWeek.count == 7 {
                result.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            result.append(currentWeek)
        }
        return result
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendrier d'assiduité")
                        .font(.headline.weight(.bold))
                    Text("Régularité des 16 dernières semaines")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                let totalSessions = heatmapDays.reduce(0) { $0 + $1.workoutCount }
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(totalSessions) séances")
                        .font(.caption.weight(.bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(10)
            }

            // Grille de contribution horizontale avec scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 5) {
                    // Symboles des jours
                    VStack(spacing: 5) {
                        ForEach(0..<7, id: \.self) { idx in
                            Text(daySymbols[idx])
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 14, height: 14)
                        }
                    }
                    .padding(.trailing, 4)

                    // Colonnes de semaines
                    ForEach(0..<weeks.count, id: \.self) { weekIndex in
                        let week = weeks[weekIndex]
                        VStack(spacing: 5) {
                            ForEach(0..<week.count, id: \.self) { dayIndex in
                                let day = week[dayIndex]
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(colorForIntensity(day.intensityLevel))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 3)
                                            .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            // Légende des niveaux
            HStack(spacing: 6) {
                Text("Moins")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ForEach(0...4, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForIntensity(level))
                        .frame(width: 11, height: 11)
                }

                Text("Plus")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func colorForIntensity(_ level: Int) -> Color {
        switch level {
        case 0: return Color(uiColor: .tertiarySystemFill)
        case 1: return Color.green.opacity(0.35)
        case 2: return Color.green.opacity(0.6)
        case 3: return Color.green.opacity(0.85)
        case 4: return Color.green
        default: return Color(uiColor: .tertiarySystemFill)
        }
    }
}
