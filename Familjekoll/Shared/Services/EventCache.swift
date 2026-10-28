import Foundation

struct EventCache: Sendable {
    private let eventsKey = "cachedFamilyEvents"

    func load() -> [FamilyEvent] {
        guard let data = AppConfiguration.sharedDefaults.data(forKey: eventsKey) else { return [] }
        return (try? JSONDecoder().decode([FamilyEvent].self, from: data)) ?? []
    }

    func save(_ events: [FamilyEvent], updatedAt: Date = Date()) {
        guard let data = try? JSONEncoder().encode(events) else { return }
        AppConfiguration.sharedDefaults.set(data, forKey: eventsKey)
        AppConfiguration.sharedDefaults.set(updatedAt, forKey: AppConfiguration.lastUpdatedKey)
    }

    var lastUpdated: Date? {
        AppConfiguration.sharedDefaults.object(forKey: AppConfiguration.lastUpdatedKey) as? Date
    }
}
