import Foundation

enum ProjectTaskStatus: String, CaseIterable, Codable, Identifiable {
    case planned = "Planned"
    case acquired = "Acquired"
    case installed = "Installed"
    case skipped = "Skipped"

    var id: String { rawValue }
}

struct ProjectTask: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var category: String
    var estimatedCost: Double
    var actualCost: Double?
    var required: Bool
    var status: ProjectTaskStatus = .planned
    var sourceURL: String? = nil
    var sourceTitle: String? = nil
    var sourceProvider: String? = nil
}

struct BuildProject: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var vehicle: VehicleListing
    var mission: MissionType
    var targetBudget: Double
    var createdAt = Date()
    var tasks: [ProjectTask]
    var notes: String = ""

    var estimatedTotal: Double {
        tasks
            .filter { $0.status != .skipped }
            .reduce(vehicle.price) { $0 + $1.estimatedCost }
    }

    var actualSpent: Double {
        tasks.reduce(vehicle.price) { total, task in
            total + (task.actualCost ?? 0)
        }
    }

    var completionFraction: Double {
        let active = tasks.filter { $0.status != .skipped }
        guard !active.isEmpty else { return 0 }
        let done = active.filter { $0.status == .installed }.count
        return Double(done) / Double(active.count)
    }

    static func from(evaluation: BuildEvaluation, targetBudget: Double) -> BuildProject {
        BuildProject(
            name: "\(evaluation.listing.year) \(evaluation.listing.make) \(evaluation.listing.model) • \(evaluation.mission.rawValue)",
            vehicle: evaluation.listing,
            mission: evaluation.mission,
            targetBudget: targetBudget,
            tasks: evaluation.parts.map {
                ProjectTask(
                    title: $0.name,
                    category: $0.category,
                    estimatedCost: $0.estimate,
                    actualCost: nil,
                    required: $0.required,
                    status: $0.required ? .planned : .skipped
                )
            }
        )
    }

    static func from(sourcedPlan: SourcedBuildPlan, targetBudget: Double) -> BuildProject {
        BuildProject(
            name: "\(sourcedPlan.listing.year) \(sourcedPlan.listing.make) \(sourcedPlan.listing.model) • Sourced \(sourcedPlan.evaluation.mission.rawValue)",
            vehicle: sourcedPlan.listing,
            mission: sourcedPlan.evaluation.mission,
            targetBudget: targetBudget,
            tasks: sourcedPlan.lines.map { line in
                let cheapest = line.cheapest
                return ProjectTask(
                    title: line.task.label,
                    category: line.task.category,
                    estimatedCost: line.planningCost,
                    actualCost: nil,
                    required: line.task.required,
                    status: line.task.required ? .planned : .skipped,
                    sourceURL: cheapest?.url,
                    sourceTitle: cheapest?.title,
                    sourceProvider: cheapest?.provider
                )
            }
        )
    }
}
