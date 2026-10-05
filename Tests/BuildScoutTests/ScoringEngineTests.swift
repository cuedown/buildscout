import Testing
@testable import BuildScout

@Test("Manual RWD beats engine-less RX-8 for a cheap drift mission")
func manualRWDRanksHigher() {
    var mission = MissionProfile()
    mission.type = .drift
    mission.vehicleBudget = 3000
    mission.totalBudget = 5000

    let e90 = SeedData.listings[0]
    let rx8 = SeedData.listings[1]

    #expect(
        ScoringEngine.evaluate(e90, mission: mission).score >
        ScoringEngine.evaluate(rx8, mission: mission).score
    )
}
