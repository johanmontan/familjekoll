import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                FamilyTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        hero
                        content
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .accessibilityLabel("Inställningar")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView {
                    await viewModel.configurationDidChange()
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FAMILJEKOLL")
                .font(.caption.weight(.bold))
                .tracking(1.8)
                .foregroundStyle(FamilyTheme.accent)

            Text(greeting)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(FamilyTheme.ink)

            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(FamilyTheme.secondaryInk)
            }
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading where viewModel.events.isEmpty:
            LoadingCard()
        case .needsSetup:
            SetupCard { showingSettings = true }
            if !viewModel.events.isEmpty { daySections }
        case .failed(let message) where viewModel.events.isEmpty:
            ErrorCard(message: message) {
                Task { await viewModel.refresh() }
            }
        default:
            daySections
        }
    }

    private var daySections: some View {
        VStack(alignment: .leading, spacing: 26) {
            if viewModel.weekEvents.isEmpty {
                EmptyCalendarCard()
            } else {
                ForEach(0..<viewModel.weekDates.count, id: \.self) { offset in
                    let date = viewModel.weekDates[offset]
                    let eventGroups = viewModel.eventGroups(on: date)
                    if offset < 2 || !eventGroups.isEmpty {
                        DaySection(
                            title: dayTitle(for: date, offset: offset),
                            date: date,
                            events: eventGroups,
                            emptyText: emptyText(for: offset)
                        )
                    }
                }
            }

            categoryLegend
        }
    }

    private func dayTitle(for date: Date, offset: Int) -> String {
        if offset == 0 { return "Idag" }
        if offset == 1 { return "Imorgon" }
        return date
            .formatted(.dateTime.weekday(.wide))
            .capitalized(with: Locale(identifier: "sv_SE"))
    }

    private func emptyText(for offset: Int) -> String {
        if offset == 0 { return "Inget viktigt inlagt idag" }
        if offset == 1 { return "Inget viktigt inlagt imorgon" }
        return "Inget viktigt inlagt"
    }

    private var categoryLegend: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Familjen")
                .font(.headline)
                .foregroundStyle(FamilyTheme.ink)

            FlowLayout(spacing: 8) {
                ForEach(FamilyCategory.allCases, id: \.self) { category in
                    Label(category.shortName, systemImage: category.symbolName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(category.color.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "God morgon"
        case 10..<17: return "Hej familjen"
        default: return "God kväll"
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .failed: .orange
        case .needsSetup: .orange
        case .loading: .blue
        case .loaded: FamilyTheme.accent
        }
    }

    private var statusText: String {
        switch viewModel.state {
        case .loading: "Hämtar familjens kalender…"
        case .needsSetup: "Google Sheet behöver anslutas"
        case .failed: "Kunde inte uppdatera just nu"
        case .loaded:
            if let date = viewModel.lastUpdated {
                "Uppdaterad \(date.formatted(date: .omitted, time: .shortened))"
            } else {
                "Uppdaterad"
            }
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let availableWidth = proposal.width ?? 320
        let result = arrangement(width: availableWidth, subviews: subviews)
        return CGSize(width: min(availableWidth, result.width), height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(width: bounds.width, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                proposal: .unspecified
            )
        }
    }

    private func arrangement(width: CGFloat, subviews: Subviews) -> (points: [CGPoint], width: CGFloat, height: CGFloat) {
        var points: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maximumWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maximumWidth = max(maximumWidth, x)
        }

        return (points, maximumWidth, y + lineHeight)
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: CalendarViewModel())
    }
}
#endif
