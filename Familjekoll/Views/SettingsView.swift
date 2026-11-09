import SwiftUI
import UserNotifications
import WidgetKit

struct SettingsView: View {
    private enum SettingsTab: Hashable {
        case general
        case notifications
    }

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: SettingsTab = .notifications
    @State private var endpoint: String
    @State private var preferredCategory: FamilyCategory?
    @State private var notificationsEnabled: Bool
    @State private var notificationRules: [String]
    @State private var notificationTime: Date
    @State private var draftRule = ""
    @State private var selectedSuggestedTitle = ""
    @State private var permissionStatus: UNAuthorizationStatus = .notDetermined
    @State private var validationMessage: String?
    @State private var isSaving = false
    @FocusState private var isEditingEndpoint: Bool
    @FocusState private var isEditingRule: Bool

    private let events: [FamilyEvent]
    private let notificationScheduler = NotificationScheduler()
    let onSave: () async -> Void

    init(events: [FamilyEvent], onSave: @escaping () async -> Void) {
        self.events = events
        self.onSave = onSave
        _endpoint = State(initialValue: AppConfiguration.endpointURLString)
        _preferredCategory = State(initialValue: AppConfiguration.preferredCategory)
        _notificationsEnabled = State(initialValue: AppConfiguration.notificationsEnabled)
        _notificationRules = State(initialValue: AppConfiguration.notificationRules)
        _notificationTime = State(
            initialValue: Self.timeDate(minutes: AppConfiguration.notificationTimeMinutes)
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            notificationSettings
                .tabItem {
                    Label("Notiser", systemImage: "bell.badge")
                }
                .tag(SettingsTab.notifications)

            generalSettings
                .tabItem {
                    Label("Allmänt", systemImage: "slider.horizontal.3")
                }
                .tag(SettingsTab.general)
        }
        .interactiveDismissDisabled(isSaving)
        .task {
            permissionStatus = await notificationScheduler.authorizationStatus()
        }
        .overlay {
            if isSaving {
                savingOverlay
                    .transition(.opacity)
            }
        }
    }

    private var generalSettings: some View {
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
                    Label("Visar idag och sex dagar framåt", systemImage: "calendar")
                    Label("Delar cache med widgeten", systemImage: "rectangle.3.group")
                }

                Section {
                    Text("Urvalet använder datum, kategori, klockslag och viktiga nyckelord. AI kan läggas på servern senare utan att en hemlig API-nyckel byggs in i appen.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Inställningar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbar }
        }
    }

    private var notificationSettings: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Aktivera notiser", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { _, enabled in
                            guard enabled else { return }
                            requestNotificationPermission()
                        }

                    if notificationsEnabled {
                        DatePicker(
                            "Tid dagen före",
                            selection: $notificationTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                    Label(permissionDescription, systemImage: permissionSymbol)
                        .font(.footnote)
                        .foregroundStyle(permissionColor)
                } header: {
                    Text("Påminnelse")
                } footer: {
                    Text("Notisen skapas lokalt på telefonen och visas dagen före aktiviteten. Kommande aktiviteter hämtas för 60 dagar när appen uppdateras.")
                }

                Section {
                    if notificationRules.isEmpty {
                        Text("Inga aktiviteter valda")
                            .foregroundStyle(.secondary)
                    }

                    ForEach(notificationRules, id: \.self) { rule in
                        HStack(spacing: 12) {
                            Label(rule, systemImage: "bell")
                            Spacer(minLength: 8)
                            Button(role: .destructive) {
                                notificationRules.removeAll { $0 == rule }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Ta bort \(rule)")
                        }
                    }
                } header: {
                    Text("Aktiviteter med notis")
                } footer: {
                    Text("Matchningen ignorerar stora bokstäver, skiljetecken och vanliga småord. Tömning, töms och tömma räknas som samma ord.")
                }

                Section {
                    HStack {
                        TextField("Skriv en aktivitet", text: $draftRule)
                            .textInputAutocapitalization(.sentences)
                            .focused($isEditingRule)
                            .submitLabel(.done)
                            .onSubmit(addDraftRule)

                        Button(action: addDraftRule) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                        }
                        .disabled(trimmedDraftRule.isEmpty)
                        .accessibilityLabel("Lägg till aktivitet")
                    }

                    if !eventTitleSuggestions.isEmpty {
                        Picker("Välj från kalendern", selection: $selectedSuggestedTitle) {
                            Text("Välj aktivitet…").tag("")
                            ForEach(eventTitleSuggestions, id: \.self) { title in
                                Text(title).tag(title)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedSuggestedTitle) { _, title in
                            guard !title.isEmpty else { return }
                            draftRule = title
                        }
                    }

                    if !trimmedDraftRule.isEmpty {
                        Label(matchDescription, systemImage: draftMatches.isEmpty ? "questionmark.circle" : "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(draftMatches.isEmpty ? .secondary : FamilyTheme.accent)
                    }
                } header: {
                    Text("Lägg till")
                } footer: {
                    Text("Dropdownen innehåller unika aktivitetsnamn från den hämtade kalendern. Du kan också skriva en friare regel.")
                }
            }
            .navigationTitle("Notiser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbar }
        }
    }

    @ToolbarContentBuilder
    private var settingsToolbar: some ToolbarContent {
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

    private var savingOverlay: some View {
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
    }

    private var eventTitleSuggestions: [String] {
        Array(Set(events.map(\.normalizedTitle).filter { !$0.isEmpty }))
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    private var trimmedDraftRule: String {
        draftRule.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var draftMatches: [FamilyEvent] {
        NotificationRuleMatcher.matchingEvents(for: trimmedDraftRule, in: events)
    }

    private var matchDescription: String {
        let uniqueTitles = Array(Set(draftMatches.map(\.normalizedTitle)))
        guard !uniqueTitles.isEmpty else {
            return "Ingen hämtad aktivitet matchar just nu"
        }

        let examples = uniqueTitles.prefix(2).joined(separator: ", ")
        if uniqueTitles.count > 2 {
            return "Matchar \(uniqueTitles.count) aktiviteter, bland annat \(examples)"
        }
        return "Matchar \(examples)"
    }

    private var permissionDescription: String {
        switch permissionStatus {
        case .authorized, .provisional, .ephemeral:
            return "Notiser är tillåtna på den här telefonen"
        case .denied:
            return "Notiser är avstängda i iOS-inställningarna"
        case .notDetermined:
            return "Du får godkänna notiser när funktionen aktiveras"
        @unknown default:
            return "Notisbehörigheten kunde inte läsas"
        }
    }

    private var permissionSymbol: String {
        switch permissionStatus {
        case .authorized, .provisional, .ephemeral: "checkmark.circle.fill"
        case .denied: "exclamationmark.triangle.fill"
        default: "bell"
        }
    }

    private var permissionColor: Color {
        switch permissionStatus {
        case .authorized, .provisional, .ephemeral: FamilyTheme.accent
        case .denied: .orange
        default: .secondary
        }
    }

    private func requestNotificationPermission() {
        Task {
            _ = await notificationScheduler.requestAuthorization()
            let status = await notificationScheduler.authorizationStatus()
            await MainActor.run {
                permissionStatus = status
                if status == .denied {
                    notificationsEnabled = false
                }
            }
        }
    }

    private func addDraftRule() {
        let rule = trimmedDraftRule
        guard !rule.isEmpty else { return }
        guard !notificationRules.contains(where: {
            $0.compare(rule, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) else {
            draftRule = ""
            selectedSuggestedTitle = ""
            return
        }

        notificationRules.append(rule)
        draftRule = ""
        selectedSuggestedTitle = ""
        isEditingRule = false
    }

    private func save() {
        isEditingEndpoint = false
        isEditingRule = false
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedEndpoint.isEmpty {
            guard let url = URL(string: trimmedEndpoint), url.scheme == "https", url.host != nil else {
                selectedTab = .general
                validationMessage = "Kontrollera att webbadressen är en fullständig https-adress."
                return
            }
        }

        validationMessage = nil
        isSaving = true

        Task {
            var shouldEnableNotifications = notificationsEnabled
            if shouldEnableNotifications {
                var status = await notificationScheduler.authorizationStatus()
                if status == .notDetermined {
                    _ = await notificationScheduler.requestAuthorization()
                    status = await notificationScheduler.authorizationStatus()
                }
                shouldEnableNotifications = status == .authorized || status == .provisional || status == .ephemeral
            }

            await MainActor.run {
                let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: notificationTime)
                let minutes = (timeComponents.hour ?? 18) * 60 + (timeComponents.minute ?? 0)

                AppConfiguration.endpointURLString = trimmedEndpoint
                AppConfiguration.preferredCategory = preferredCategory
                AppConfiguration.notificationsEnabled = shouldEnableNotifications
                AppConfiguration.notificationRules = notificationRules
                AppConfiguration.notificationTimeMinutes = minutes
                WidgetCenter.shared.reloadAllTimelines()
            }

            await onSave()
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        }
    }

    private static func timeDate(minutes: Int) -> Date {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? start
    }
}
