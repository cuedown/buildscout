import Foundation

struct PartSearchTask: Identifiable, Hashable {
    let id = UUID()
    var category: String
    var label: String
    var query: String
    var required: Bool
    var fallbackEstimate: Double
    var notes: String
}

enum PartSearchPlanner {
    static func tasks(
        for listing: VehicleListing,
        mission: MissionProfile,
        evaluation: BuildEvaluation
    ) -> [PartSearchTask] {
        let vehicle = "\(listing.year) \(listing.make) \(listing.model)"
        var tasks: [PartSearchTask] = []

        for part in evaluation.parts {
            if let mapped = map(part: part, vehicle: vehicle) {
                tasks.append(mapped)
            }
        }

        switch mission.type {
        case .drift:
            tasks.append(contentsOf: [
                .init(
                    category: "Chassis",
                    label: "Coilovers / dampers",
                    query: "\(vehicle) coilovers suspension",
                    required: false,
                    fallbackEstimate: 1200,
                    notes: "Compare against simply refreshing worn OE suspension."
                ),
                .init(
                    category: "Steering",
                    label: "Angle hardware",
                    query: "\(vehicle) drift angle kit steering angle",
                    required: false,
                    fallbackEstimate: 850,
                    notes: "Not required for first seat time; useful later."
                ),
                .init(
                    category: "Safety",
                    label: "Fixed-back seat / mount",
                    query: "\(vehicle) FIA fixed back seat bracket mount",
                    required: false,
                    fallbackEstimate: 800,
                    notes: "Mounting and event rules matter more than bargain pricing."
                )
            ])

            if listing.transmission != .manual && mission.allowTransmissionSwap {
                tasks.append(.init(
                    category: "Drivetrain",
                    label: "Manual donor / swap kit",
                    query: "\(vehicle) manual transmission swap kit donor gearbox pedals driveshaft",
                    required: false,
                    fallbackEstimate: 1800,
                    notes: "Prefer complete donor packages over piecemeal gearbox-only purchases."
                ))
            }

            if !listing.runs {
                tasks.append(.init(
                    category: "Drivetrain",
                    label: "Engine / long block donor",
                    query: "\(vehicle) engine long block donor",
                    required: false,
                    fallbackEstimate: 1500,
                    notes: "Only source an engine after diagnosis proves the existing one is uneconomical."
                ))
            }

        case .overland:
            tasks.append(contentsOf: [
                .init(category: "Protection", label: "Skid plates", query: "\(vehicle) skid plate underbody protection", required: false, fallbackEstimate: 500, notes: ""),
                .init(category: "Recovery", label: "Recovery points", query: "\(vehicle) recovery points tow hooks", required: false, fallbackEstimate: 300, notes: ""),
                .init(category: "Cargo", label: "Roof / cargo system", query: "\(vehicle) roof rack cargo platform", required: false, fallbackEstimate: 700, notes: "")
            ])

        case .camper:
            tasks.append(contentsOf: [
                .init(category: "Electrical", label: "12V power system", query: "12v camper power station dc fuse panel vehicle", required: false, fallbackEstimate: 700, notes: ""),
                .init(category: "Interior", label: "Ventilation", query: "vehicle camper ventilation fan window insert", required: false, fallbackEstimate: 250, notes: "")
            ])

        case .rally:
            tasks.append(contentsOf: [
                .init(category: "Protection", label: "Skid plate", query: "\(vehicle) rally skid plate", required: true, fallbackEstimate: 600, notes: ""),
                .init(category: "Chassis", label: "Rally dampers / springs", query: "\(vehicle) rally suspension gravel coilovers", required: false, fallbackEstimate: 1600, notes: "")
            ])

        case .track:
            tasks.append(contentsOf: [
                .init(category: "Brakes", label: "Track pads", query: "\(vehicle) track brake pads high temperature", required: true, fallbackEstimate: 450, notes: ""),
                .init(category: "Cooling", label: "Cooling upgrades", query: "\(vehicle) oil cooler radiator track", required: false, fallbackEstimate: 700, notes: "")
            ])

        case .winter:
            tasks.append(.init(
                category: "Traction",
                label: "Winter tires",
                query: "\(vehicle) winter tires wheel package",
                required: true,
                fallbackEstimate: 1000,
                notes: ""
            ))

        case .custom:
            break
        }

        return dedupe(tasks)
    }

    private static func map(part: BuildPart, vehicle: String) -> PartSearchTask? {
        let lower = part.name.lowercased()

        if lower.contains("differential") {
            return .init(
                category: part.category,
                label: part.name,
                query: "\(vehicle) LSD limited slip differential",
                required: part.required,
                fallbackEstimate: part.estimate,
                notes: "For road-driven cars, prefer a proper LSD over a permanently locked differential."
            )
        }

        if lower.contains("manual swap") {
            return .init(
                category: part.category,
                label: part.name,
                query: "\(vehicle) manual transmission swap complete",
                required: part.required,
                fallbackEstimate: part.estimate,
                notes: "Search complete donor packages: gearbox, clutch/flywheel, pedals, hydraulics, shifter and driveshaft."
            )
        }

        if lower.contains("fluids") || lower.contains("baseline service") {
            return .init(
                category: part.category,
                label: part.name,
                query: "\(vehicle) maintenance kit oil filter spark plugs belts coolant",
                required: part.required,
                fallbackEstimate: part.estimate,
                notes: ""
            )
        }

        if lower.contains("brake") {
            return .init(
                category: part.category,
                label: part.name,
                query: "\(vehicle) brake pads rotors high performance",
                required: part.required,
                fallbackEstimate: part.estimate,
                notes: ""
            )
        }

        if lower.contains("tire") {
            return .init(
                category: part.category,
                label: part.name,
                query: "\(vehicle) tires wheels used",
                required: part.required,
                fallbackEstimate: part.estimate,
                notes: ""
            )
        }

        if lower.contains("suspension") {
            return .init(
                category: part.category,
                label: part.name,
                query: "\(vehicle) suspension refresh control arms shocks bushings",
                required: part.required,
                fallbackEstimate: part.estimate,
                notes: ""
            )
        }

        return nil
    }

    private static func dedupe(_ tasks: [PartSearchTask]) -> [PartSearchTask] {
        var seen = Set<String>()
        return tasks.filter {
            let key = $0.query.lowercased()
            guard seen.insert(key).inserted else { return false }
            return true
        }
    }
}
