import SwiftUI

struct EventCard: View {
    let eventGroup: FamilyEventGroup

    private var event: FamilyEvent { eventGroup.event }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(event.category.color.opacity(0.14))
                HStack(spacing: eventGroup.categories.count > 2 ? -3 : 2) {
                    ForEach(eventGroup.categories.prefix(3), id: \.self) { category in
                        Image(systemName: category.symbolName)
                            .font(.system(size: eventGroup.categories.count == 1 ? 17 : 12, weight: .bold))
                            .foregroundStyle(category.color)
                    }
                }
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text(categoryLabel)
                    .font(.caption2.weight(.heavy))
                    .tracking(0.8)
                    .foregroundStyle(event.category.color)

                Text(event.normalizedTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(FamilyTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(FamilyTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .leading) {
            Capsule()
                .fill(event.category.color)
                .frame(width: 4)
                .padding(.vertical, 12)
        }
        .shadow(color: .black.opacity(0.045), radius: 14, y: 5)
        .accessibilityElement(children: .combine)
    }

    private var categoryLabel: String {
        eventGroup.categories
            .map { $0.shortName.uppercased() }
            .joined(separator: " + ")
    }
}
