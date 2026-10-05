import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ListingStore
    @State private var section: SidebarSection = .mission

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $section) { item in
                Label(item.rawValue, systemImage: item.symbol).tag(item)
            }
            .navigationTitle("BuildScout")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OPEN SOURCE").font(.caption2).bold()
                    Text("Build the car, not the debt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } detail: {
            switch section {
            case .mission: MissionView()
            case .hunter: HunterView()
            case .candidates: CandidateBrowser()
            case .projects: ProjectsView()
            case .importListings: ImportView()
            case .sources: SourcesView()
            case .garage: GarageView()
            case .support: SupportView()
            }
        }
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case mission = "Mission"
    case hunter = "Hunter"
    case candidates = "Candidates"
    case projects = "Projects"
    case importListings = "Import"
    case sources = "Sources"
    case garage = "Garage"
    case support = "Support"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .mission: return "scope"
        case .hunter: return "binoculars"
        case .candidates: return "car.2"
        case .projects: return "wrench.and.screwdriver"
        case .importListings: return "square.and.arrow.down"
        case .sources: return "antenna.radiowaves.left.and.right"
        case .garage: return "wrench.adjustable"
        case .support: return "heart"
        }
    }
}
