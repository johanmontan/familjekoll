import Foundation

enum AppConfiguration {
    static let appGroup = "group.mojo.Familjekoll.shared"
    static let endpointKey = "googleAppsScriptEndpoint"
    static let lastUpdatedKey = "lastUpdated"
    static let preferredCategoryKey = "preferredCategory"
    static let notificationsEnabledKey = "notificationsEnabled"
    static let notificationRulesKey = "notificationRules"
    static let notificationTimeMinutesKey = "notificationTimeMinutes"

    static let defaultNotificationRules = [
        "Tömning av trädgårdsavfall",
        "Månadsmöte"
    ]

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static var endpointURLString: String {
        get { sharedDefaults.string(forKey: endpointKey) ?? "" }
        set {
            let cleanValue = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            sharedDefaults.set(cleanValue, forKey: endpointKey)
        }
    }

    static var endpointURL: URL? {
        guard let url = URL(string: endpointURLString),
              url.scheme == "https",
              url.host != nil else {
            return nil
        }
        return url
    }

    static var preferredCategory: FamilyCategory? {
        get {
            guard let rawValue = sharedDefaults.string(forKey: preferredCategoryKey),
                  let category = FamilyCategory(rawValue: rawValue),
                  category == .johan || category == .emma else {
                return nil
            }
            return category
        }
        set {
            if let newValue {
                sharedDefaults.set(newValue.rawValue, forKey: preferredCategoryKey)
            } else {
                sharedDefaults.removeObject(forKey: preferredCategoryKey)
            }
        }
    }

    static var notificationsEnabled: Bool {
        get { sharedDefaults.object(forKey: notificationsEnabledKey) as? Bool ?? false }
        set { sharedDefaults.set(newValue, forKey: notificationsEnabledKey) }
    }

    static var notificationRules: [String] {
        get { sharedDefaults.stringArray(forKey: notificationRulesKey) ?? defaultNotificationRules }
        set { sharedDefaults.set(newValue, forKey: notificationRulesKey) }
    }

    static var notificationTimeMinutes: Int {
        get {
            guard sharedDefaults.object(forKey: notificationTimeMinutesKey) != nil else {
                return 18 * 60
            }
            return sharedDefaults.integer(forKey: notificationTimeMinutesKey)
        }
        set { sharedDefaults.set(max(0, min(newValue, 23 * 60 + 59)), forKey: notificationTimeMinutesKey) }
    }
}
