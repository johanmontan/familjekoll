import Foundation

enum PreviewData {
    static func events(now: Date = Date(), calendar: Calendar = .current) -> [FamilyEvent] {
        let today = LocalDay.today(calendar: calendar, now: now)
        let tomorrow = LocalDay.tomorrow(calendar: calendar, now: now)

        return [
            FamilyEvent(
                id: "preview-today",
                date: today,
                title: "Vårgårda frukost 09.30",
                category: .johan,
                sourceColumn: "Johans liv",
                priority: 72
            ),
            FamilyEvent(
                id: "preview-tomorrow",
                date: tomorrow,
                title: "Ogio visit to ALS",
                category: .johan,
                sourceColumn: "Johans liv",
                priority: 54
            ),
        ]
    }
}
