import SwiftUI

@main
struct BuildScoutApp: App {
    @StateObject private var store = ListingStore()
    @StateObject private var connections = ConnectionStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(connections)
                .preferredColorScheme(.dark)
                .tint(BuildScoutTheme.accent)
                .frame(minWidth: 1180, minHeight: 760)
                .background(BuildScoutTheme.background)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1380, height: 900)
    }
}
