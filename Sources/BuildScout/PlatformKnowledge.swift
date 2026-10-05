import Foundation

struct PlatformProfile: Identifiable, Hashable {
    let id: String
    let aliases: [String]
    let bestMissions: Set<MissionType>
    let partsAvailability: Int
    let fabricationFriendliness: Int
    let knownRisks: [String]
    let driftNotes: [String]
}

enum PlatformKnowledge {
    static let profiles: [PlatformProfile] = [
        .init(id: "BMW E30", aliases: ["e30", "325e", "325i"], bestMissions: [.drift, .rally, .track], partsAvailability: 7, fabricationFriendliness: 9, knownRisks: ["Structural rust", "Age-related cooling and rubber"], driftNotes: ["Light RWD chassis", "Manual drivetrains are valuable; avoid paying collector tax"]),
        .init(id: "BMW E36", aliases: ["e36", "318i", "318is", "318ti", "323i", "325i", "328i"], bestMissions: [.drift, .track], partsAvailability: 10, fabricationFriendliness: 10, knownRisks: ["Rear chassis / subframe inspection", "Cooling system age"], driftNotes: ["Huge donor ecosystem", "M5x engines and manual gearboxes make cheap combinations possible"]),
        .init(id: "BMW E46", aliases: ["e46", "325ci", "325i", "328i", "330ci", "330i"], bestMissions: [.drift, .track], partsAvailability: 10, fabricationFriendliness: 9, knownRisks: ["Rear axle carrier panel cracks", "Cooling system"], driftNotes: ["Excellent budget geometry", "330 variants reduce the urge to power-swap immediately"]),
        .init(id: "BMW E90", aliases: ["e90", "323i", "325i", "328i", "330i"], bestMissions: [.drift, .track, .winter], partsAvailability: 9, fabricationFriendliness: 8, knownRisks: ["Oil leaks", "Electric / hydraulic accessory faults"], driftNotes: ["N52 + 6MT RWD cars can be exceptional seat-time value"]),
        .init(id: "Nissan Z33", aliases: ["350z", "z33"], bestMissions: [.drift, .track], partsAvailability: 10, fabricationFriendliness: 9, knownRisks: ["Oil consumption on some engines", "Rear bushings / axles"], driftNotes: ["Excellent angle and suspension aftermarket", "Finished drift cars can outperform DIY economics"]),
        .init(id: "Infiniti G35", aliases: ["g35", "v35"], bestMissions: [.drift, .track], partsAvailability: 9, fabricationFriendliness: 9, knownRisks: ["Oil consumption", "Worn suspension bushings"], driftNotes: ["Shares much of the Z33 ecosystem", "Sedans can be cheaper than 350Zs"]),
        .init(id: "Ford Mustang SN95/New Edge", aliases: ["sn95", "new edge", "mustang gt", "mustang 5.0"], bestMissions: [.drift, .track], partsAvailability: 10, fabricationFriendliness: 9, knownRisks: ["Abused drivetrains", "Chassis rust"], driftNotes: ["Torque and cheap parts are the appeal", "Transmission condition matters"]),
        .init(id: "Mazda RX-8", aliases: ["rx-8", "rx8"], bestMissions: [.drift, .track], partsAvailability: 7, fabricationFriendliness: 7, knownRisks: ["Rotary compression", "Engine-swap scope creep"], driftNotes: ["Brilliant chassis", "A cheap engine-less shell is often not a cheap finished car"]),
        .init(id: "Hyundai Genesis Coupe", aliases: ["genesis coupe", "bk1", "bk2"], bestMissions: [.drift, .track], partsAvailability: 7, fabricationFriendliness: 7, knownRisks: ["Abuse history", "Differential and gearbox condition"], driftNotes: ["Factory RWD package", "Compare complete-car price against older BMWs and Z cars"]),
        .init(id: "Volvo 740/940", aliases: ["volvo 740", "volvo 940", "740 turbo", "940 turbo"], bestMissions: [.drift, .winter, .rally], partsAvailability: 6, fabricationFriendliness: 9, knownRisks: ["Rust", "Aging wiring / bushings"], driftNotes: ["Simple RWD architecture", "Turbo redblock cars are especially desirable"]),
        .init(id: "Lexus IS300", aliases: ["is300", "altezza"], bestMissions: [.drift, .track], partsAvailability: 8, fabricationFriendliness: 8, knownRisks: ["Toyota tax", "Manual cars command a premium"], driftNotes: ["Strong chassis and engine ecosystem", "Automatic examples only make sense if the conversion math works"])
    ]

    static func match(_ listing: VehicleListing) -> PlatformProfile? {
        let haystack = "\(listing.title) \(listing.make) \(listing.model)".lowercased()
        return profiles.first { profile in
            profile.aliases.contains(where: { haystack.contains($0.lowercased()) })
        }
    }

    static func scoreAdjustment(for listing: VehicleListing, mission: MissionType) -> (Int, [String], [String]) {
        guard let profile = match(listing) else { return (0, [], []) }
        var score = 0
        var reasons: [String] = ["Recognized platform: \(profile.id)."]
        var warnings = profile.knownRisks

        if profile.bestMissions.contains(mission) {
            score += 8
            reasons.append("\(profile.id) is a proven fit for \(mission.rawValue.lowercased()) builds.")
        }
        score += max(0, profile.partsAvailability - 5)
        score += max(0, profile.fabricationFriendliness - 6)

        if mission == .drift {
            reasons.append(contentsOf: profile.driftNotes)
        }

        if profile.partsAvailability <= 6 {
            warnings.append("Regional donor/parts availability may dominate the budget.")
        }

        return (score, reasons, warnings)
    }
}
