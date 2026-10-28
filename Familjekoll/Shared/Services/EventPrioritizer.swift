import Foundation

struct EventPrioritizer: Sendable {
    private let pastEventGraceInterval: TimeInterval = 90 * 60

    func score(
        _ event: FamilyEvent,
        today: String,
        tomorrow: String,
        preferredCategory: FamilyCategory? = nil
    ) -> Int {
        var score = event.priority
        let title = event.title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)

        if event.date == today { score += 30 }
        if event.date == tomorrow { score += 15 }

        let strongSignals = [
            "läkare", "tandläk", "bvc", "mvc", "vaccin", "sjuk", "förskol", "skola",
            "möte", "resa", "flyg", "tåg", "kalas", "födelsedag", "hämt", "lämn",
            "deadline", "stängt", "avslutas", "leverans"
        ]
        score += strongSignals.filter(title.contains).count * 12

        if title.range(of: #"\b([01]?\d|2[0-3])[:.]\d{2}\b"#, options: .regularExpression) != nil {
            score += 8
        }

        if event.category == .annat { score -= 4 }
        if event.category == preferredCategory { score += 10 }
        return score
    }

    func sorted(
        _ events: [FamilyEvent],
        now: Date = Date(),
        calendar: Calendar = .current,
        preferredCategory: FamilyCategory? = nil
    ) -> [FamilyEvent] {
        let today = LocalDay.today(calendar: calendar, now: now)
        let tomorrow = LocalDay.tomorrow(calendar: calendar, now: now)

        return events.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            let leftScore = score(lhs, today: today, tomorrow: tomorrow, preferredCategory: preferredCategory)
            let rightScore = score(rhs, today: today, tomorrow: tomorrow, preferredCategory: preferredCategory)
            if leftScore != rightScore { return leftScore > rightScore }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    func grouped(
        _ events: [FamilyEvent],
        now: Date = Date(),
        calendar: Calendar = .current,
        preferredCategory: FamilyCategory? = nil
    ) -> [FamilyEventGroup] {
        let orderedEvents = sorted(
            events,
            now: now,
            calendar: calendar,
            preferredCategory: preferredCategory
        )
        var keys: [String] = []
        var eventsByKey: [String: [FamilyEvent]] = [:]

        for event in orderedEvents {
            let key = duplicateKey(for: event)
            if eventsByKey[key] == nil { keys.append(key) }
            eventsByKey[key, default: []].append(event)
        }

        return keys.compactMap { key in
            guard let matchingEvents = eventsByKey[key], let first = matchingEvents.first else {
                return nil
            }
            let primary = matchingEvents.first { $0.category == preferredCategory } ?? first
            var seenCategories = Set<FamilyCategory>()
            let categories = matchingEvents
                .map(\.category)
                .filter { seenCategories.insert($0).inserted }

            return FamilyEventGroup(
                id: key,
                event: primary,
                categories: categories
            )
        }
    }

    func isStillRelevant(
        _ event: FamilyEvent,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Bool {
        let today = LocalDay.today(calendar: calendar, now: now)
        guard event.date >= today else { return false }
        guard event.date == today, let startTime = scheduledDate(for: event, calendar: calendar) else {
            return true
        }

        return now < startTime.addingTimeInterval(pastEventGraceInterval)
    }

    func nextVisibilityChange(
        in events: [FamilyEvent],
        after now: Date = Date(),
        calendar: Calendar = .current
    ) -> Date? {
        let today = LocalDay.today(calendar: calendar, now: now)
        return events
            .filter { $0.date == today }
            .compactMap { scheduledDate(for: $0, calendar: calendar) }
            .map { $0.addingTimeInterval(pastEventGraceInterval) }
            .filter { $0 > now }
            .min()
    }

    func topEvents(
        from events: [FamilyEvent],
        limit: Int = 2,
        now: Date = Date(),
        calendar: Calendar = .current,
        preferredCategory: FamilyCategory? = nil
    ) -> [FamilyEvent] {
        let today = LocalDay.today(calendar: calendar, now: now)
        let tomorrow = LocalDay.tomorrow(calendar: calendar, now: now)
        let start = calendar.startOfDay(for: now)
        let end = calendar.date(byAdding: .day, value: 6, to: start) ?? start
        let lastDay = LocalDay.string(from: end)
        let candidates = events.filter { event in
            guard event.date >= today && event.date <= lastDay else { return false }
            guard isStillRelevant(event, now: now, calendar: calendar) else { return false }
            return true
        }

        let orderedCandidates = candidates.sorted { lhs, rhs in
            if lhs.date != rhs.date { return lhs.date < rhs.date }
            if let preferredCategory {
                let leftIsPreferred = lhs.category == preferredCategory
                let rightIsPreferred = rhs.category == preferredCategory
                if leftIsPreferred != rightIsPreferred { return leftIsPreferred }
            }
            let leftScore = score(lhs, today: today, tomorrow: tomorrow, preferredCategory: preferredCategory)
            let rightScore = score(rhs, today: today, tomorrow: tomorrow, preferredCategory: preferredCategory)
            if leftScore != rightScore { return leftScore > rightScore }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        var seen = Set<String>()
        return orderedCandidates
        .filter { seen.insert(duplicateKey(for: $0)).inserted }
        .prefix(max(0, limit))
        .map { $0 }
    }

    private func duplicateKey(for event: FamilyEvent) -> String {
        let title = event.normalizedTitle
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return event.date + "|" + title
    }

    private func scheduledDate(for event: FamilyEvent, calendar: Calendar) -> Date? {
        guard let eventDate = event.localDate,
              let (hour, minute) = clockTime(in: event.normalizedTitle) else {
            return nil
        }

        var components = calendar.dateComponents([.year, .month, .day], from: eventDate)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = calendar.timeZone
        return calendar.date(from: components)
    }

    private func clockTime(in title: String) -> (hour: Int, minute: Int)? {
        let clockPattern = #"(?<!\d)([01]?\d|2[0-3])[:.]([0-5]\d)(?!\d)"#
        if let range = title.range(of: clockPattern, options: .regularExpression) {
            let parts = title[range].split(whereSeparator: { $0 == ":" || $0 == "." })
            if parts.count == 2,
               let hour = Int(parts[0]),
               let minute = Int(parts[1]) {
                return (hour, minute)
            }
        }

        let hourOnlyPattern = #"(?i)\bkl\.?\s*([01]?\d|2[0-3])\b"#
        if let range = title.range(of: hourOnlyPattern, options: .regularExpression) {
            let digits = title[range].filter(\.isNumber)
            if let hour = Int(digits) {
                return (hour, 0)
            }
        }

        return nil
    }
}
