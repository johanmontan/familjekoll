import Foundation

enum AppConfiguration {
    static let appGroup = "group.mojo.Familjekoll.shared"
    static let endpointKey = "googleAppsScriptEndpoint"
    static let lastUpdatedKey = "lastUpdated"
    static let preferredCategoryKey = "preferredCategory"

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
}
