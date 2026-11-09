import Foundation
import UserNotifications

enum NotificationRuleMatcher {
    static func matches(title: String, rule: String) -> Bool {
        let titleTokens = canonicalTokens(in: title)
        let ruleTokens = canonicalTokens(in: rule)

        guard !titleTokens.isEmpty, !ruleTokens.isEmpty else { return false }
        return ruleTokens.isSubset(of: titleTokens)
    }

    static func matchingEvents(
        for rule: String,
        in events: [FamilyEvent]
    ) -> [FamilyEvent] {
        events.filter { matches(title: $0.title, rule: rule) }
    }

    private static func canonicalTokens(in value: String) -> Set<String> {
        let folded = value
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "sv_SE"))
            .lowercased()

        let words = folded
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        let stopWords: Set<String> = [
            "av", "den", "det", "en", "ett", "for", "i", "och", "pa", "som", "till"
        ]

        return Set(words.compactMap { word in
            guard !stopWords.contains(word) else { return nil }

            // Samlar svenska varianter som "tömning", "töms" och "tömma".
            if word.hasPrefix("tom") { return "tom" }
            return word
        })
    }
}

struct NotificationScheduler: Sendable {
    static let identifierPrefix = "familjekoll.event."
    private let maximumScheduledNotifications = 60

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
        } catch {
            return false
        }
    }

    func reschedule(events: [FamilyEvent], now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let existingIdentifiers = pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }

        if !existingIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: existingIdentifiers)
        }

        guard AppConfiguration.notificationsEnabled,
              !AppConfiguration.notificationRules.isEmpty else {
            return
        }

        let status = await authorizationStatus()
        guard status == .authorized || status == .provisional || status == .ephemeral else {
            return
        }

        let calendar = Calendar.current
        let notificationTime = AppConfiguration.notificationTimeMinutes
        let hour = notificationTime / 60
        let minute = notificationTime % 60
        let rules = AppConfiguration.notificationRules
        var seenEvents = Set<String>()

        let candidates = events
            .filter { event in
                rules.contains { NotificationRuleMatcher.matches(title: event.title, rule: $0) }
            }
            .sorted {
                ($0.localDate ?? .distantFuture) < ($1.localDate ?? .distantFuture)
            }
            .compactMap { event -> (FamilyEvent, Date)? in
                guard let eventDate = event.localDate,
                      let previousDay = calendar.date(byAdding: .day, value: -1, to: eventDate),
                      let fireDate = calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: previousDay
                      ),
                      fireDate > now else {
                    return nil
                }

                let key = "\(event.date)|\(event.normalizedTitle.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current))"
                guard seenEvents.insert(key).inserted else { return nil }
                return (event, fireDate)
            }
            .prefix(maximumScheduledNotifications)

        for (event, fireDate) in candidates {
            let content = UNMutableNotificationContent()
            content.title = "Imorgon"
            content.body = event.title
            content.sound = .default
            content.userInfo = ["eventID": event.id, "eventDate": event.date]

            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let identifier = Self.identifierPrefix + event.id + "." + event.date
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }
}
