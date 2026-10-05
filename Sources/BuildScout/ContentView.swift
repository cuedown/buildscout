import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ListingStore
    @State private var section: SidebarSection = .mission

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 232)

            Rectangle()
                .fill(BuildScoutTheme.border)
                .frame(width: 1)

            ZStack {
                BuildScoutTheme.background
                    .ignoresSafeArea()

                detailView
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(BuildScoutTheme.background)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(BuildScoutTheme.accent)
                        .frame(width: 36, height: 36)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.black)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("BUILDSCOUT")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(1.0)
                    Text("PROJECT VEHICLE INTEL")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1.15)
                        .foregroundStyle(BuildScoutTheme.faint)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 28)

            Text("WORKSPACE")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(BuildScoutTheme.faint)
                .padding(.horizontal, 19)
                .padding(.bottom, 8)

            VStack(spacing: 4) {
                ForEach(SidebarSection.allCases) { item in
                    Button {
                        section = item
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.symbol)
                                .frame(width: 20)
                                .font(.system(size: 14, weight: .semibold))
                            Text(item.rawValue)
                                .font(.system(size: 13, weight: section == item ? .bold : .medium))
                            Spacer()
                            if item == .candidates && !store.listings.isEmpty {
                                Text("\(store.listings.count)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundStyle(section == item ? .black : BuildScoutTheme.muted)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(section == item ? Color.white.opacity(0.85) : Color.white.opacity(0.08))
                                    )
                            }
                        }
                        .foregroundStyle(section == item ? .white : BuildScoutTheme.muted)
                        .padding(.horizontal, 13)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(section == item ? BuildScoutTheme.accent.opacity(0.18) : Color.clear)
                        )
                        .overlay(alignment: .leading) {
                            if section == item {
                                Capsule()
                                    .fill(BuildScoutTheme.accent)
                                    .frame(width: 3, height: 22)
                                    .offset(x: -1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            ScoutPanel {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Circle()
                            .fill(BuildScoutTheme.success)
                            .frame(width: 7, height: 7)
                        Text("LOCAL-FIRST")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .tracking(1.1)
                    }
                    Text("Free, open source, and built to save project-car money.")
                        .font(.caption)
                        .foregroundStyle(BuildScoutTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
        }
        .background(BuildScoutTheme.sidebar)
    }

    @ViewBuilder
    private var detailView: some View {
        switch section {
        case .mission: MissionView()
        case .hunter: HunterView()
        case .vehicleIntel: VehicleIntelView()
        case .candidates: CandidateBrowser()
        case .projects: ProjectsView()
        case .importListings: ImportView()
        case .sources: SourcesView()
        case .garage: GarageView()
        case .support: SupportView()
        }
    }
}

enum SidebarSection: String, CaseIterable, Identifiable {
    case mission = "Mission"
    case hunter = "Hunter"
    case vehicleIntel = "Vehicle Intel"
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
        case .hunter: return "binoculars.fill"
        case .vehicleIntel: return "barcode.viewfinder"
        case .candidates: return "car.side.fill"
        case .projects: return "wrench.and.screwdriver.fill"
        case .importListings: return "square.and.arrow.down.fill"
        case .sources: return "antenna.radiowaves.left.and.right"
        case .garage: return "garage.open.trianglebadge.exclamationmark"
        case .support: return "heart.fill"
        }
    }
}
