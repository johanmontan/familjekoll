import Foundation
import WidgetKit

@MainActor
final class CalendarViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case needsSetup
        case failed(String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var events: [FamilyEvent] = []
    @Published private(set) var lastUpdated: Date?

    private let client: SheetAPIClient
    private let cache: EventCache
    private let prioritizer: EventPrioritizer
    private var hasLoaded = false

    init(
        client: SheetAPIClient = SheetAPIClient(),
        cache: EventCache = EventCache(),
        prioritizer: EventPrioritizer = EventPrioritizer()
    ) {
        self.client = client
        self.cache = cache
        self.prioritizer = prioritizer
        self.events = prioritizer.sorted(
            cache.load(),
            preferredCategory: AppConfiguration.preferredCategory
        )
        self.lastUpdated = cache.lastUpdated
    }

    var todayEvents: [FamilyEventGroup] {
        eventGroups(on: Date())
    }

    var tomorrowEvents: [FamilyEventGroup] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return eventGroups(on: tomorrow)
    }

    var topEvents: [FamilyEvent] {
        prioritizer.topEvents(
            from: events,
            preferredCategory: AppConfiguration.preferredCategory
        )
    }

    var weekDates: [Date] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }

    var weekEvents: [FamilyEvent] {
        let days = Set(weekDates.map { LocalDay.string(from: $0) })
        return events.filter { days.contains($0.date) }
    }

    func eventGroups(on date: Date) -> [FamilyEventGroup] {
        let day = LocalDay.string(from: date)
        return prioritizer.grouped(
            events.filter { $0.date == day },
            preferredCategory: AppConfiguration.preferredCategory
        )
    }

    var isConfigured: Bool {
        AppConfiguration.endpointURL != nil
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await refresh()
    }

    func refresh() async {
        let cachedEvents = cache.load()
        if events.isEmpty, !cachedEvents.isEmpty {
            events = prioritizer.sorted(
                cachedEvents,
                preferredCategory: AppConfiguration.preferredCategory
            )
            lastUpdated = cache.lastUpdated
        }

        guard isConfigured else {
            state = .needsSetup
            return
        }

        if events.isEmpty { state = .loading }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let endOfWeek = calendar.date(byAdding: .day, value: 6, to: start) ?? start

        do {
            let fetched = try await client.fetchEvents(from: start, through: endOfWeek)
            let sorted = prioritizer.sorted(
                fetched,
                preferredCategory: AppConfiguration.preferredCategory
            )
            events = sorted
            lastUpdated = Date()
            cache.save(sorted, updatedAt: lastUpdated ?? Date())
            state = .loaded
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            if events.isEmpty {
                state = .failed(error.localizedDescription)
            } else {
                state = .loaded
            }
        }
    }

    func configurationDidChange() async {
        hasLoaded = true
        state = .loading
        await refresh()
    }
}
