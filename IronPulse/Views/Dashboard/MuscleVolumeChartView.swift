import SwiftUI
import Charts

public struct MuscleVolumeChartView: View {
    public let volumeItems: [MuscleVolumeItem]
    @Binding public var selectedFilter: TimeFilter

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Volume par groupe musculaire")
                        .font(.headline.weight(.bold))
                    Text("Équilibre et répartition des charges")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // Sélecteur de période (7j / 30j / Tout)
                Picker("Période", selection: $selectedFilter) {
                    ForEach(TimeFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 170)
            }

            let activeItems = volumeItems.filter { $0.totalVolumeKg > 0 }

            if activeItems.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.6))
                    Text("Aucun entraînement enregistré sur cette période")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 160)
            } else {
                Chart(activeItems) { item in
                    BarMark(
                        x: .value("Volume (kg)", item.totalVolumeKg),
                        y: .value("Groupe musculaire", item.muscle.displayName)
                    )
                    .foregroundStyle(item.muscle.color.gradient)
                    .cornerRadius(6)
                    .annotation(position: .trailing) {
                        Text("\(item.totalSets) séries")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                }
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let val = value.as(Double.self) {
                                if val >= 1000 {
                                    Text("\(Int(val / 1000))t")
                                } else {
                                    Text("\(Int(val))kg")
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: CGFloat(max(180, activeItems.count * 32)))
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
