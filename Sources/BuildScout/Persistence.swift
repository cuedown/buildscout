import Foundation

struct PersistedState: Codable {
    var schemaVersion: Int? = 2
    var mission: MissionProfile
    var listings: [VehicleListing]
    var favoriteIDs: Set<UUID>
    var garage: GarageProfile?
    var projects: [BuildProject]?
}

enum PersistenceStore {
    private static var stateURL: URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("BuildScout", isDirectory: true)
        try? fm.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("state.json")
    }

    static func load() -> PersistedState? {
        guard let data = try? Data(contentsOf: stateURL) else { return nil }
        return try? JSONDecoder().decode(PersistedState.self, from: data)
    }

    static func save(_ state: PersistedState) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(state)
            try data.write(to: stateURL, options: [.atomic])
        } catch {
            fputs("BuildScout persistence error: \(error)\n", stderr)
        }
    }
}
