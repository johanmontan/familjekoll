import Foundation

struct FamilyEvent: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let date: String
    let title: String
    let category: FamilyCategory
    let sourceColumn: String
    let priority: Int

    var localDate: Date? {
        LocalDay.date(from: date)
    }

    var normalizedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct FamilyEventGroup: Identifiable, Hashable, Sendable {
    let id: String
    let event: FamilyEvent
    let categories: [FamilyCategory]
}

struct SheetResponse: Codable, Sendable {
    let generatedAt: String?
    let timeZone: String?
    let events: [FamilyEvent]
    let error: String?
}

enum LocalDay {
    private static let lock = NSLock()
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func string(from date: Date) -> String {
        lock.lock()
        defer { lock.unlock() }
        return formatter.string(from: date)
    }

    static func date(from string: String) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return formatter.date(from: string)
    }

    static func today(calendar: Calendar = .current, now: Date = Date()) -> String {
        string(from: calendar.startOfDay(for: now))
    }

    static func tomorrow(calendar: Calendar = .current, now: Date = Date()) -> String {
        let start = calendar.startOfDay(for: now)
        return string(from: calendar.date(byAdding: .day, value: 1, to: start) ?? start)
    }
}
