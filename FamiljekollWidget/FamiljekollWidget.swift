import SwiftUI
import WidgetKit

struct FamiljekollEntry: TimelineEntry {
    let date: Date
    let events: [FamilyEvent]
    let isConfigured: Bool
    let isStale: Bool
}

struct FamiljekollProvider: TimelineProvider {
    private let cache = EventCache()
    private let prioritizer = EventPrioritizer()

    func placeholder(in context: Context) -> FamiljekollEntry {
        FamiljekollEntry(
            date: Date(),
            events: PreviewData.events(),
            isConfigured: true,
            isStale: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FamiljekollEntry) -> Void) {
        let cached = prioritizer.topEvents(
            from: cache.load(),
            preferredCategory: AppConfiguration.preferredCategory
        )
        completion(FamiljekollEntry(
            date: Date(),
            events: cached.isEmpty && context.isPreview ? PreviewData.events() : cached,
            isConfigured: AppConfiguration.endpointURL != nil,
            isStale: false
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FamiljekollEntry>) -> Void) {
        Task {
            let now = Date()
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: now)
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: start) ?? start
            let nextMidnight = calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(3600)
            let periodicRefresh = now.addingTimeInterval(30 * 60)

            var candidates = cache.load()
            var isStale = !candidates.isEmpty

            if AppConfiguration.endpointURL != nil {
                do {
                    candidates = try await SheetAPIClient().fetchEvents(from: start, through: endOfWeek)
                    cache.save(candidates, updatedAt: now)
                    isStale = false
                } catch {
                    isStale = true
                }
            }

            let nextEventExpiry = prioritizer.nextVisibilityChange(
                in: candidates,
                after: now,
                calendar: calendar
            )?.addingTimeInterval(1)
            let refreshDate = [
                periodicRefresh,
                nextMidnight.addingTimeInterval(60),
                nextEventExpiry,
            ]
            .compactMap { $0 }
            .min() ?? periodicRefresh

            let entry = FamiljekollEntry(
                date: now,
                events: prioritizer.topEvents(
                    from: candidates,
                    now: now,
                    calendar: calendar,
                    preferredCategory: AppConfiguration.preferredCategory
                ),
                isConfigured: AppConfiguration.endpointURL != nil,
                isStale: isStale
            )
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }
}

struct FamiljekollWidget: Widget {
    let kind = "FamiljekollWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FamiljekollProvider()) { entry in
            FamiljekollWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    FamilyTheme.background
                }
                .widgetURL(URL(string: "familjekoll://today"))
        }
        .configurationDisplayName("Familjekoll")
        .description("Den kommande veckans viktigaste familjehändelser.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryInline,
            .accessoryCircular,
        ])
    }
}

#if DEBUG
struct FamiljekollWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FamiljekollWidgetView(
                entry: FamiljekollEntry(
                    date: Date(),
                    events: PreviewData.events(),
                    isConfigured: true,
                    isStale: false
                )
            )
            .previewContext(WidgetPreviewContext(family: .systemMedium))

            FamiljekollWidgetView(
                entry: FamiljekollEntry(
                    date: Date(),
                    events: PreviewData.events(),
                    isConfigured: true,
                    isStale: false
                )
            )
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
        }
    }
}
#endif
