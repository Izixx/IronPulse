import SwiftUI

public struct RPEPickerView: View {
    @Binding public var selectedRPE: Double?
    @Environment(\.dismiss) private var dismiss

    private let rpeValues: [(value: Double, label: String, desc: String)] = [
        (10.0, "@ 10", "Échec absolu, 0 rep en réserve"),
        (9.5, "@ 9.5", "Pas de rep en plus, charge max"),
        (9.0, "@ 9", "1 répétition en réserve"),
        (8.5, "@ 8.5", "1 à 2 répétitions en réserve"),
        (8.0, "@ 8", "2 répétitions en réserve"),
        (7.5, "@ 7.5", "2 à 3 répétitions en réserve"),
        (7.0, "@ 7", "3 répétitions en réserve"),
        (6.5, "@ 6.5", "Barre qui ralentit un peu"),
        (6.0, "@ 6", "Série facile d'échauffement lourd (4+ RIR)")
    ]

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Intensité de la série (RPE)")) {
                    Button(action: {
                        selectedRPE = nil
                        dismiss()
                    }) {
                        HStack {
                            Text("Aucun RPE spécifié")
                                .foregroundColor(.secondary)
                            Spacer()
                            if selectedRPE == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }

                    ForEach(rpeValues, id: \.value) { item in
                        Button(action: {
                            selectedRPE = item.value
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            dismiss()
                        }) {
                            HStack(alignment: .center, spacing: 12) {
                                Text(item.label)
                                    .font(.headline)
                                    .frame(width: 60, alignment: .leading)
                                    .foregroundColor(colorForRPE(item.value))

                                Text(item.desc)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Spacer()

                                if selectedRPE == item.value {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.orange)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Échelle d'effort RPE")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func colorForRPE(_ rpe: Double) -> Color {
        if rpe >= 9.5 { return .red }
        if rpe >= 8.5 { return .orange }
        if rpe >= 7.5 { return .yellow }
        return .green
    }
}
