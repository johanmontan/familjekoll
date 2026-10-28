import SwiftUI

struct DaySection: View {
    let title: String
    let date: Date
    let events: [FamilyEventGroup]
    let emptyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(FamilyTheme.ink)
                Spacer()
                Text(date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FamilyTheme.secondaryInk)
            }

            if events.isEmpty {
                Label(emptyText, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(FamilyTheme.secondaryInk)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(FamilyTheme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ForEach(events) { eventGroup in
                    EventCard(eventGroup: eventGroup)
                }
            }
        }
    }
}
