import SwiftUI

@main
struct FamiljekollApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = CalendarViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .tint(FamilyTheme.accent)
                .onOpenURL { _ in
                    Task { await viewModel.refresh() }
                }
                .task {
                    await viewModel.loadIfNeeded()
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await viewModel.refresh() }
        }
    }
}
