import SwiftUI
import WidgetKit

struct FamiljekollWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: FamiljekollEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            inlineView
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var inlineView: some View {
        Label(inlineText, systemImage: entry.events.first?.category.symbolName ?? "calendar")
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: entry.events.first?.category.symbolName ?? "calendar")
                    .font(.headline)
                Text("\(entry.events.count)")
                    .font(.caption2.bold())
            }
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("FAMILJEKOLL")
                .font(.caption2.bold())
            if let first = entry.events.first {
                Label(first.normalizedTitle, systemImage: first.category.symbolName)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if entry.events.count > 1 {
                    Text("+ \(entry.events[1].normalizedTitle)")
                        .font(.caption2)
                        .lineLimit(1)
                }
            } else {
                Text(emptyText)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 9) {
            widgetHeader
            if entry.events.isEmpty {
                Spacer(minLength: 0)
                emptyState
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(entry.events.prefix(2)) { event in
                        HStack(alignment: .top, spacing: 7) {
                            Image(systemName: event.category.symbolName)
                                .font(.caption.bold())
                                .foregroundStyle(event.category.color)
                                .frame(width: 24, height: 24)
                                .background(
                                    event.category.color.opacity(0.13),
                                    in: RoundedRectangle(cornerRadius: 7)
                                )
                            VStack(alignment: .leading, spacing: 1) {
                                Text(dayLabel(for: event))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(event.category.color)
                                Text(event.normalizedTitle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(FamilyTheme.ink)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 10) {
            widgetHeader
            if entry.events.isEmpty {
                Spacer()
                emptyState
                Spacer()
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(entry.events.prefix(2)) { event in
                        HStack(spacing: 10) {
                            Image(systemName: event.category.symbolName)
                                .font(.body.bold())
                                .foregroundStyle(event.category.color)
                                .frame(width: 28, height: 28)
                                .background(event.category.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(dayLabel(for: event))
                                    .font(.caption2.bold())
                                    .foregroundStyle(event.category.color)
                                Text(event.normalizedTitle)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(FamilyTheme.ink)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var widgetHeader: some View {
        HStack {
            Text("Familjekoll")
                .font(.system(size: 10, weight: .medium))
                .tracking(0.35)
                .foregroundStyle(FamilyTheme.accent)
            Spacer()
            if entry.isStale {
                Image(systemName: "arrow.clockwise")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 5) {
            Image(systemName: entry.isConfigured ? "checkmark.circle.fill" : "link.badge.plus")
                .foregroundStyle(FamilyTheme.accent)
            Text(emptyText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FamilyTheme.ink)
                .lineLimit(2)
        }
    }

    private var emptyText: String {
        entry.isConfigured ? "Lugnt den kommande veckan" : "Öppna appen och anslut Google Sheet"
    }

    private var inlineText: String {
        guard let first = entry.events.first else { return emptyText }
        return "\(dayLabel(for: first)): \(first.normalizedTitle)"
    }

    private func dayLabel(for event: FamilyEvent) -> String {
        if event.date == LocalDay.today(now: entry.date) { return "IDAG" }
        if event.date == LocalDay.tomorrow(now: entry.date) { return "IMORGON" }
        guard let date = event.localDate else { return event.date }
        return date.formatted(.dateTime.weekday(.wide)).uppercased()
    }
}
