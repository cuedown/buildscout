import XCTest
@testable import BuildScout

final class ScoringEngineTests: XCTestCase {
    func testManualRWDBeatsEngineLessRX8ForCheapDriftMission() {
        var mission = MissionProfile()
        mission.type = .drift
        mission.vehicleBudget = 3000
        mission.totalBudget = 5000

        let e90 = SeedData.listings[0]
        let rx8 = SeedData.listings[1]

        XCTAssertGreaterThan(
            ScoringEngine.evaluate(e90, mission: mission).score,
            ScoringEngine.evaluate(rx8, mission: mission).score
        )
    }
}
