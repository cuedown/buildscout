import Foundation
import Combine

@MainActor
final class ListingStore: ObservableObject {
    @Published var mission: MissionProfile {
        didSet { persist() }
    }
    @Published var listings: [VehicleListing] {
        didSet { persist() }
    }
    @Published var favoriteIDs: Set<UUID> {
        didSet { persist() }
    }
    @Published var garage: GarageProfile {
        didSet { persist() }
    }
    @Published var projects: [BuildProject] {
        didSet { persist() }
    }

    @Published var selectedListingID: UUID?
    @Published var query = ""
    @Published var favoritesOnly = false

    init() {
        if let state = PersistenceStore.load() {
            mission = state.mission
            listings = state.listings
            favoriteIDs = state.favoriteIDs
            garage = state.garage ?? .starter
            projects = state.projects ?? []
        } else {
            mission = MissionProfile()
            listings = SeedData.listings
            favoriteIDs = []
            garage = .starter
            projects = []
        }
    }

    var evaluations: [BuildEvaluation] {
        listings
            .filter { listing in
                let matchesQuery = query.isEmpty ||
                    listing.title.localizedCaseInsensitiveContains(query) ||
                    listing.make.localizedCaseInsensitiveContains(query) ||
                    listing.model.localizedCaseInsensitiveContains(query) ||
                    listing.location.localizedCaseInsensitiveContains(query)
                let matchesFavorite = !favoritesOnly || favoriteIDs.contains(listing.id)
                return matchesQuery && matchesFavorite
            }
            .map { ScoringEngine.evaluate($0, mission: mission, garage: garage) }
            .sorted {
                if $0.score == $1.score { return $0.projectedTotal < $1.projectedTotal }
                return $0.score > $1.score
            }
    }

    var selectedEvaluation: BuildEvaluation? {
        guard let selectedListingID else { return evaluations.first }
        return evaluations.first(where: { $0.listing.id == selectedListingID }) ?? evaluations.first
    }

    func addListing(_ listing: VehicleListing) {
        listings.insert(listing, at: 0)
        selectedListingID = listing.id
    }

    func addListings(_ newListings: [VehicleListing]) {
        guard !newListings.isEmpty else { return }
        listings.insert(contentsOf: newListings, at: 0)
        selectedListingID = newListings.first?.id
    }

    func remove(_ listing: VehicleListing) {
        listings.removeAll { $0.id == listing.id }
        favoriteIDs.remove(listing.id)
        if selectedListingID == listing.id {
            selectedListingID = nil
        }
    }

    func toggleFavorite(_ listing: VehicleListing) {
        if favoriteIDs.contains(listing.id) {
            favoriteIDs.remove(listing.id)
        } else {
            favoriteIDs.insert(listing.id)
        }
    }

    func startProject(from evaluation: BuildEvaluation) {
        if projects.contains(where: { $0.vehicle.id == evaluation.listing.id && $0.mission == evaluation.mission }) {
            return
        }
        projects.insert(
            BuildProject.from(evaluation: evaluation, targetBudget: mission.totalBudget),
            at: 0
        )
    }

    func removeProject(_ id: UUID) {
        projects.removeAll { $0.id == id }
    }

    func resetDemoData() {
        mission = MissionProfile()
        listings = SeedData.listings
        favoriteIDs = []
        garage = .starter
        projects = []
        selectedListingID = nil
        query = ""
    }

    private func persist() {
        PersistenceStore.save(
            PersistedState(
                mission: mission,
                listings: listings,
                favoriteIDs: favoriteIDs,
                garage: garage,
                projects: projects
            )
        )
    }
}
