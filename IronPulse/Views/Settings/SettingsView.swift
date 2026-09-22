import SwiftUI
import SwiftData
import UniformTypeIdentifiers

public struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("defaultRestDuration") private var defaultRestDuration: Double = 90
    @AppStorage("enableReminders") private var enableReminders: Bool = false
    @AppStorage("reminderHour") private var reminderHour: Int = 18
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0

    @State private var showingExportShareSheet = false
    @State private var exportFileURL: URL? = nil

    @State private var showingImportPicker = false
    @State private var importAlertTitle = ""
    @State private var importAlertMessage = ""
    @State private var showingImportAlert = false

    @State private var isHealthKitEnabled = false

    public var body: some View {
        NavigationStack {
            Form {
                // Section Sideload & Sauvegarde (Pérennité des données)
                Section(
                    header: Text("Sauvegarde & Sideload"),
                    footer: Text("En cas d'installation via Sideloadly avec un compte Apple gratuit (7 jours), exportez régulièrement vos données pour les réimporter après réinstallation.")
                ) {
                    Button(action: exportJSON) {
                        Label("Exporter la sauvegarde (JSON)", systemImage: "arrow.up.doc.fill")
                            .foregroundColor(.orange)
                    }

                    Button(action: { showingImportPicker = true }) {
                        Label("Importer une sauvegarde (JSON)", systemImage: "arrow.down.doc.fill")
                            .foregroundColor(.blue)
                    }

                    Button(action: exportCSV) {
                        Label("Exporter les séances (CSV pour Excel)", systemImage: "tablecells.badge.ellipsis")
                            .foregroundColor(.green)
                    }
                }

                // Section Entraînement & Minuteur
                Section(header: Text("Minuteur de repos par défaut")) {
                    Picker("Durée par défaut", selection: $defaultRestDuration) {
                        Text("30 secondes").tag(30.0)
                        Text("60 secondes").tag(60.0)
                        Text("90 secondes (1m30)").tag(90.0)
                        Text("120 secondes (2 min)").tag(120.0)
                        Text("180 secondes (3 min)").tag(180.0)
                    }
                }

                // Section Santé & Poids
                Section(header: Text("Santé & Corps")) {
                    NavigationLink(destination: BodyWeightView()) {
                        Label("Suivi du poids de corps", systemImage: "scalemass.fill")
                    }

                    Toggle(isOn: $isHealthKitEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Synchronisation Apple Santé")
                            Text("Enregistre les entraînements dans l'app Santé")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .onChange(of: isHealthKitEnabled) { _, newValue in
                        if newValue {
                            HealthKitManager.shared.requestAuthorization { success in
                                if !success {
                                    isHealthKitEnabled = false
                                }
                            }
                        }
                    }
                }

                // Section Rappels d'entraînement (Notifications locales)
                Section(header: Text("Rappels d'entraînement (Locaux)")) {
                    Toggle("Activer les rappels", isOn: $enableReminders)
                        .onChange(of: enableReminders) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestAuthorization { granted in
                                    if granted {
                                        scheduleReminders()
                                    } else {
                                        enableReminders = false
                                    }
                                }
                            } else {
                                NotificationManager.shared.cancelAllReminders()
                            }
                        }

                    if enableReminders {
                        DatePicker(
                            "Heure de rappel",
                            selection: Binding(
                                get: {
                                    var comps = DateComponents()
                                    comps.hour = reminderHour
                                    comps.minute = reminderMinute
                                    return Calendar.current.date(from: comps) ?? Date()
                                },
                                set: { date in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    reminderHour = comps.hour ?? 18
                                    reminderMinute = comps.minute ?? 0
                                    scheduleReminders()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                }

                // Section À propos
                Section(header: Text("À propos")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0 (Native Sideload)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Données")
                        Spacer()
                        Text("100% locales (SwiftData)")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .sheet(isPresented: $showingExportShareSheet) {
                if let url = exportFileURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert(importAlertTitle, isPresented: $showingImportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importAlertMessage)
            }
        }
    }

    private func exportJSON() {
        do {
            let url = try BackupService.exportAllDataToJSON(modelContext: modelContext)
            self.exportFileURL = url
            self.showingExportShareSheet = true
        } catch {
            importAlertTitle = "Erreur d'export"
            importAlertMessage = error.localizedDescription
            showingImportAlert = true
        }
    }

    private func exportCSV() {
        do {
            let url = try BackupService.exportWorkoutsToCSV(modelContext: modelContext)
            self.exportFileURL = url
            self.showingExportShareSheet = true
        } catch {
            importAlertTitle = "Erreur d'export"
            importAlertMessage = error.localizedDescription
            showingImportAlert = true
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let secure = url.startAccessingSecurityScopedResource()
            defer {
                if secure { url.stopAccessingSecurityScopedResource() }
            }

            do {
                let stats = try BackupService.importDataFromJSON(url: url, modelContext: modelContext)
                importAlertTitle = "Importation réussie !"
                importAlertMessage = "\(stats.workoutsCount) séance(s) importée(s) avec succès dans votre historique."
                showingImportAlert = true
            } catch {
                importAlertTitle = "Erreur d'importation"
                importAlertMessage = error.localizedDescription
                showingImportAlert = true
            }
        case .failure(let error):
            importAlertTitle = "Erreur"
            importAlertMessage = error.localizedDescription
            showingImportAlert = true
        }
    }

    private func scheduleReminders() {
        // Planifier les rappels pour Lundi, Mercredi, Vendredi
        for day in [2, 4, 6] {
            NotificationManager.shared.scheduleWorkoutReminder(weekday: day, hour: reminderHour, minute: reminderMinute)
        }
    }
}

// MARK: - UIActivityViewController Wrapper pour ShareLink natif
public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
