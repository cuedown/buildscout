import Foundation

struct BuildGraphNode: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var category: String
    var estimate: Double
    var required: Bool
    var dependsOnTitles: [String]
}

struct BuildGraph {
    var nodes: [BuildGraphNode]

    var total: Double {
        nodes.filter(\.required).reduce(0) { $0 + $1.estimate }
    }
}

enum BuildGraphBuilder {
    static func make(for evaluation: BuildEvaluation) -> BuildGraph {
        var nodes: [BuildGraphNode] = [
            .init(
                title: "Acquire candidate",
                category: "Vehicle",
                estimate: evaluation.listing.price,
                required: true,
                dependsOnTitles: []
            )
        ]

        for part in evaluation.parts {
            let dependencies = dependencies(for: part, evaluation: evaluation)
            nodes.append(
                .init(
                    title: part.name,
                    category: part.category,
                    estimate: part.estimate,
                    required: part.required,
                    dependsOnTitles: dependencies
                )
            )
        }

        return BuildGraph(nodes: nodes)
    }

    private static func dependencies(for part: BuildPart, evaluation: BuildEvaluation) -> [String] {
        switch part.name {
        case "Manual swap reserve":
            return ["Acquire candidate"]
        case "Differential solution":
            return evaluation.listing.transmission == .manual
                ? ["Acquire candidate"]
                : ["Acquire candidate", "Manual swap reserve"]
        case "Alignment / inspection":
            let chassisWork = evaluation.parts
                .filter { $0.category == "Chassis" && $0.name != part.name }
                .map(\.name)
            return ["Acquire candidate"] + chassisWork
        case "Rear tire reserve":
            return ["Alignment / inspection"]
        default:
            return ["Acquire candidate"]
        }
    }
}
