import SwiftUI
import WidgetKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var endpoint = AppConfiguration.endpointURLString
    @State private var preferredCategory = AppConfiguration.preferredCategory
    @State private var validationMessage: String?
    @State private var isSaving = false
    @FocusState private var isEditingEndpoint: Bool

    let onSave: () async -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://script.google.com/macros/s/…/exec", text: $endpoint, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .focused($isEditingEndpoint)

                    if let validationMessage {
                        Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Google Sheet")
                } footer: {
                    Text("Använd webbadressen som slutar på /exec. En eventuell nyckel kan ligga kvar som ?key=…")
                }

                Section {
                    Picker("Prioritera", selection: $preferredCategory) {
                        Text("Ingen").tag(nil as FamilyCategory?)
                        Text("Johan").tag(FamilyCategory.johan as FamilyCategory?)
                        Text("Emma").tag(FamilyCategory.emma as FamilyCategory?)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Personligt urval")
                } footer: {
                    Text("Sparas bara på den här telefonen och ger personens händelser förtur när widgeten måste välja.")
                }

                Section("Så fungerar det") {
                    Label("Läser bara fliken 2022-25", systemImage: "tablecells")
                    Label("Hämtar idag och sex dagar framåt", systemImage: "calendar")
                    Label("Delar cache med widgeten", systemImage: "rectangle.3.group")
                }

                Section {
                    Text("Urvalet använder i denna första version datum, kategori, klockslag och viktiga nyckelord. AI kan läggas på servern senare utan att en hemlig API-nyckel byggs in i appen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Inställningar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") { save() }
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                }
            }
        }
        .interactiveDismissDisabled(isSaving)
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.38)
                        .ignoresSafeArea()

                    VStack(spacing: 14) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(FamilyTheme.accent)
                        Text("Sparar och uppdaterar…")
                            .font(.headline)
                            .foregroundStyle(FamilyTheme.ink)
                    }
                    .padding(.horizontal, 26)
                    .padding(.vertical, 22)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .transition(.opacity)
            }
        }
    }

    private func save() {
        isEditingEndpoint = false
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty {
            guard let url = URL(string: trimmed), url.scheme == "https", url.host != nil else {
                validationMessage = "Kontrollera att webbadressen är en fullständig https-adress."
                return
            }
        }

        validationMessage = nil
        isSaving = true
        AppConfiguration.endpointURLString = trimmed
        AppConfiguration.preferredCategory = preferredCategory
        WidgetCenter.shared.reloadAllTimelines()
        Task {
            await onSave()
            isSaving = false
            dismiss()
        }
    }
}
