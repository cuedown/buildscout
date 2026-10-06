import Foundation

enum MissionCandidateValidator {
    static func allows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        if listing.price > 0, listing.price > mission.vehicleBudget * 1.15 {
            return false
        }

        if !mission.allowNonRunner, !listing.runs {
            return false
        }

        if !mission.allowTow, listing.towRequired {
            return false
        }

        switch mission.type {
        case .drift:
            return driftAllows(listing, mission: mission)
        case .overland:
            return overlandAllows(listing, mission: mission)
        case .camper:
            return camperAllows(listing)
        case .rally:
            return rallyAllows(listing, mission: mission)
        case .track:
            return trackAllows(listing)
        case .winter:
            return winterAllows(listing, mission: mission)
        case .custom:
            return drivetrainPreferenceAllows(listing, mission: mission)
        }
    }

    static func isFinalistEligible(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        guard allows(listing, mission: mission) else {
            return false
        }

        if mission.type == .drift {
            // Finalists need positive RWD evidence. We never promote an
            // unverified drivetrain into an A→Z drift build.
            return listing.drivetrain == .rwd ||
                hasPositiveRWDEvidence(listing)
        }

        return true
    }

    static func rejectionReason(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> String? {
        if listing.price > 0, listing.price > mission.vehicleBudget * 1.15 {
            return "over vehicle budget"
        }

        if !mission.allowNonRunner, !listing.runs {
            return "non-runner excluded"
        }

        if !mission.allowTow, listing.towRequired {
            return "tow-required excluded"
        }

        if mission.type == .drift {
            if isObviousUtilityVehicle(listing) {
                return "utility / van / pickup body rejected for default drift mission"
            }

            switch listing.drivetrain {
            case .rwd:
                break
            case .unknown:
                if !hasPositiveRWDEvidence(listing) {
                    return "RWD not positively established"
                }
            default:
                return "not RWD"
            }

            if !mission.allowTransmissionSwap,
               listing.transmission != .manual {
                return "factory/manual transmission required"
            }
        }

        if mission.preferredDrivetrain != .unknown,
           listing.drivetrain != .unknown,
           listing.drivetrain != mission.preferredDrivetrain {
            return "wrong drivetrain"
        }

        return nil
    }

    private static func driftAllows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        guard !isObviousUtilityVehicle(listing) else {
            return false
        }

        // Drift candidates must have positive RWD evidence. Unknown is not
        // treated as "probably fine", because that promoted FWD cars and vans.
        switch listing.drivetrain {
        case .rwd:
            break
        case .unknown:
            guard hasPositiveRWDEvidence(listing) else {
                return false
            }
        default:
            return false
        }

        if !mission.allowTransmissionSwap,
           listing.transmission != .manual {
            return false
        }

        return true
    }

    private static func overlandAllows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        if mission.preferredDrivetrain != .unknown {
            if listing.drivetrain != .unknown,
               listing.drivetrain != mission.preferredDrivetrain {
                return false
            }
        } else if listing.drivetrain == .fwd {
            return false
        }

        return !containsAny(listing, needles: [
            "convertible", "roadster"
        ])
    }

    private static func camperAllows(_ listing: VehicleListing) -> Bool {
        !containsAny(listing, needles: [
            "motorcycle", "atv", "side by side"
        ])
    }

    private static func rallyAllows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        if mission.preferredDrivetrain != .unknown,
           listing.drivetrain != .unknown,
           listing.drivetrain != mission.preferredDrivetrain {
            return false
        }

        return listing.drivetrain != .fwd ||
            PlatformKnowledge.match(listing) != nil
    }

    private static func trackAllows(_ listing: VehicleListing) -> Bool {
        !isObviousUtilityVehicle(listing)
    }

    private static func winterAllows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        if mission.preferredDrivetrain != .unknown,
           listing.drivetrain != .unknown,
           listing.drivetrain != mission.preferredDrivetrain {
            return false
        }
        return true
    }

    private static func drivetrainPreferenceAllows(
        _ listing: VehicleListing,
        mission: MissionProfile
    ) -> Bool {
        guard mission.preferredDrivetrain != .unknown else {
            return true
        }

        return listing.drivetrain == .unknown ||
            listing.drivetrain == mission.preferredDrivetrain
    }

    private static func hasPositiveRWDEvidence(
        _ listing: VehicleListing
    ) -> Bool {
        if listing.drivetrain == .rwd {
            return true
        }

        let haystack = text(for: listing)

        if containsAnyText(haystack, needles: [
            " rwd ",
            "rear wheel drive",
            "rear-wheel drive",
            "drivetrain: rwd"
        ]) {
            return true
        }

        if containsAnyText(haystack, needles: [
            "awd", "all wheel drive", "all-wheel drive",
            "4wd", "4x4",
            "fwd", "front wheel drive", "front-wheel drive",
            "xdrive", " quattro ", "4matic"
        ]) {
            return false
        }

        // These are model families whose production layout is sufficiently
        // well-established to qualify a sparse listing for drift discovery.
        if let profile = PlatformKnowledge.match(listing),
           profile.bestMissions.contains(.drift) {
            return true
        }

        return containsAnyText(haystack, needles: [
            "mazda miata", "mazda mx-5", "mx5",
            "honda s2000",
            "toyota 86", "gt86", "scion fr-s", "scion frs",
            "subaru brz",
            "nissan 370z", "nissan 350z",
            "infiniti g35", "infiniti g37",
            "ford mustang",
            "chevrolet camaro", "pontiac firebird", "trans am",
            "lexus is300", "lexus sc300", "lexus sc400",
            "toyota supra",
            "hyundai genesis coupe",
            "mazda rx-7", "mazda rx7", "mazda rx-8", "mazda rx8",
            "volvo 240", "volvo 740", "volvo 940"
        ])
    }

    private static func isObviousUtilityVehicle(
        _ listing: VehicleListing
    ) -> Bool {
        let haystack = text(for: listing)

        return containsAnyText(haystack, needles: [
            "body style: suv",
            "body style: van",
            "body style: minivan",
            "body style: pickup",
            "sport utility",
            "crossover",
            "econoline",
            "e-series",
            "e150", "e-150",
            "e250", "e-250",
            "e350", "e-350",
            "cargo van",
            "passenger van",
            "conversion van",
            "minivan",
            "transit van",
            "ford transit",
            "express van",
            "chevy express",
            "chevrolet express",
            "savana",
            "promaster",
            "sprinter",
            "shuttle bus",
            "school bus",
            "ambulance",
            "motorhome",
            "motor home",
            " rv ",
            "box truck",
            "cube van",
            "step van",
            "dump truck",
            "flatbed truck",
            "pickup truck",
            "ford f-150", "ford f150", "ford f 150",
            "ford f-250", "ford f250", "ford f 250",
            "ford f-350", "ford f350", "ford f 350",
            "silverado",
            "sierra 1500", "sierra 2500", "sierra 3500",
            "ram 1500", "ram 2500", "ram 3500",
            "dodge dakota",
            "gmc sonoma",
            "chevrolet s10", "chevrolet s-10",
            "toyota tundra",
            "toyota tacoma",
            "nissan frontier",
            "ford ranger",
            "chevrolet colorado",
            "gmc canyon"
        ])
    }

    private static func containsAny(
        _ listing: VehicleListing,
        needles: [String]
    ) -> Bool {
        containsAnyText(text(for: listing), needles: needles)
    }

    private static func text(for listing: VehicleListing) -> String {
        " " + [
            listing.title,
            listing.make,
            listing.model,
            listing.notes
        ]
        .joined(separator: " ")
        .lowercased() + " "
    }

    private static func containsAnyText(
        _ haystack: String,
        needles: [String]
    ) -> Bool {
        needles.contains { haystack.contains($0) }
    }
}
