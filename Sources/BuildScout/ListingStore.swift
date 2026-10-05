import Foundation
import Combine

@MainActor
final class ListingStore: ObservableObject {
    @Published var mission = MissionProfile()
    @Published var listings: [VehicleListing] = SeedData.listings
    @Published var selectedListingID: UUID?
    @Published var query = ""

    var evaluations: [BuildEvaluation] {
        listings
            .filter { listing in
                query.isEmpty || listing.title.localizedCaseInsensitiveContains(query)
                || listing.make.localizedCaseInsensitiveContains(query)
                || listing.model.localizedCaseInsensitiveContains(query)
            }
            .map { ScoringEngine.evaluate($0, mission: mission) }
            .sorted { $0.score > $1.score }
    }

    var selectedEvaluation: BuildEvaluation? {
        guard let selectedListingID else { return evaluations.first }
        return evaluations.first(where: { $0.listing.id == selectedListingID })
    }

    func addListing(_ listing: VehicleListing) {
        listings.insert(listing, at: 0)
        selectedListingID = listing.id
    }
}
