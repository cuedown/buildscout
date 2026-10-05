import SwiftUI

@main
struct BuildScoutApp: App {
    @StateObject private var store = ListingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 1120, minHeight: 720)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1280, height: 820)
    }
}
