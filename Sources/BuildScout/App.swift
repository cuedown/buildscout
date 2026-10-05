import SwiftUI

@main
struct BuildScoutApp: App {
    @StateObject private var store = ListingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(BuildScoutTheme.accent)
                .frame(minWidth: 1180, minHeight: 760)
                .background(BuildScoutTheme.background)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1380, height: 900)
    }
}
