import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: ChallengeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Notifications activées", isOn: $store.preferences.notificationsEnabled)
                        .onChange(of: store.preferences.notificationsEnabled) { _, enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission()
                            }
                            store.applyNotificationPreferences()
                            store.savePreferences()
                        }

                    if store.preferences.notificationsEnabled {
                        DatePicker(
                            "Heure du rappel",
                            selection: $store.preferences.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: store.preferences.reminderTime) { _, _ in
                            store.applyNotificationPreferences()
                            store.savePreferences()
                        }
                    }
                } header: {
                    Text("Rappels")
                } footer: {
                    Text("Un rappel quotidien à l'heure choisie.")
                }

                Section {
                    Toggle("Enregistrer dans Santé", isOn: $store.preferences.healthKitEnabled)
                        .onChange(of: store.preferences.healthKitEnabled) { _, enabled in
                            if enabled {
                                HealthKitManager.shared.requestPermission { _ in }
                            }
                            store.savePreferences()
                        }
                } header: {
                    Text("Apple Santé")
                } footer: {
                    Text("Chaque séance est enregistrée comme entraînement Core Training.")
                }

                Section("Comportement") {
                    Toggle("Vibrations", isOn: $store.preferences.hapticsEnabled)
                        .onChange(of: store.preferences.hapticsEnabled) { _, _ in
                            store.savePreferences()
                        }
                    Toggle("Jour de grâce", isOn: $store.preferences.graceDayEnabled)
                        .onChange(of: store.preferences.graceDayEnabled) { _, _ in
                            store.savePreferences()
                        }
                }

                Section {
                    Button("Réinitialiser le défi", role: .destructive) {
                        showResetConfirm = true
                    }
                } footer: {
                    Text("Efface toutes les séances et repart du Jour 1.")
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .alert("Réinitialiser le défi ?", isPresented: $showResetConfirm) {
                Button("Réinitialiser", role: .destructive) { store.resetChallenge() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Toutes vos séances seront effacées.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ChallengeStore())
}
