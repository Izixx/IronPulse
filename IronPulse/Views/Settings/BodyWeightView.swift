import SwiftUI
import Charts
import SwiftData

public struct BodyWeightView: View {
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var entries: [BodyWeightEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAddSheet = false
    @State private var weightInput: String = ""
    @State private var dateInput: Date = Date()

    private var sortedChronological: [BodyWeightEntry] {
        entries.sorted { $0.date < $1.date }
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Carte du poids actuel
                if let latest = entries.first {
                    VStack(spacing: 4) {
                        Text("\(String(format: "%.1f", latest.weightKg)) kg")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)

                        Text("Dernière pesée le \(latest.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(16)
                }

                // Graphique Swift Charts de l'évolution du poids
                if sortedChronological.count >= 2 {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Courbe de poids")
                            .font(.headline.weight(.bold))

                        Chart(sortedChronological) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("Poids (kg)", entry.weightKg)
                            )
                            .foregroundStyle(Color.orange)
                            .lineStyle(StrokeStyle(lineWidth: 3))

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("Poids (kg)", entry.weightKg)
                            )
                            .foregroundStyle(Color.orange)
                            .symbolSize(30)
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding(16)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                }

                // Bouton Ajouter une pesée
                BigActionButton(
                    title: "Ajouter une pesée",
                    systemImage: "plus.circle.fill",
                    style: .primary
                ) {
                    showingAddSheet = true
                }

                // Historique des pesées
                VStack(alignment: .leading, spacing: 10) {
                    Text("Historique des pesées")
                        .font(.headline.weight(.bold))

                    if entries.isEmpty {
                        Text("Aucune pesée enregistrée pour l'instant.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(entries) { entry in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.date.formatted(date: .complete, time: .omitted))
                                        .font(.subheadline.weight(.semibold))
                                    if !entry.notes.isEmpty {
                                        Text(entry.notes)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                Text("\(String(format: "%.1f", entry.weightKg)) kg")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.orange)
                            }
                            .padding(12)
                            .background(Color(uiColor: .secondarySystemBackground))
                            .cornerRadius(10)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(entry)
                                    try? modelContext.save()
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Suivi du poids")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Nouvelle pesée")) {
                        TextField("Poids en kg (ex: 78.5)", text: $weightInput)
                            .keyboardType(.decimalPad)

                        DatePicker("Date", selection: $dateInput, displayedComponents: .date)
                    }
                }
                .navigationTitle("Enregistrer le poids")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") { showingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Ajouter") {
                            let formatted = weightInput.replacingOccurrences(of: ",", with: ".")
                            if let w = Double(formatted), w > 0 {
                                let entry = BodyWeightEntry(date: dateInput, weightKg: w)
                                modelContext.insert(entry)
                                try? modelContext.save()
                                // Synchroniser avec HealthKit
                                HealthKitManager.shared.saveBodyWeight(weightKg: w, date: dateInput)
                                weightInput = ""
                                showingAddSheet = false
                            }
                        }
                        .disabled(weightInput.isEmpty)
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}
