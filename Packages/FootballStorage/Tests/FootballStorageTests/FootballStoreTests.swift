import Foundation
import Testing
import FootballCore
@testable import FootballStorage

@Suite struct FootballStoreTests {
    private func makeStore() throws -> FootballStore {
        FootballStore(modelContainer: try FootballStore.makeContainer(inMemory: true))
    }

    @Test func replaceTeamsUpsertsAndPrunes() async throws {
        let store = try makeStore()
        let brazil = Team(id: "recBRA", name: "Brazil", code: "BRA", group: "C", flag: "🇧🇷")
        let spain = Team(id: "recESP", name: "Spain", code: "ESP", group: "H", flag: "🇪🇸")

        try await store.replaceTeams([brazil, spain])
        #expect(try await store.teams().count == 2)

        // Second sync: Spain dropped, Brazil moved group — same record updated, not duplicated.
        let movedBrazil = Team(id: "recBRA", name: "Brazil", code: "BRA", group: "D", flag: "🇧🇷")
        try await store.replaceTeams([movedBrazil])

        let teams = try await store.teams()
        #expect(teams == [movedBrazil])
    }

    @Test func replaceMatchesUpdatesScores() async throws {
        let store = try makeStore()
        let kickoff = Date(timeIntervalSince1970: 1_781_700_000)
        let scheduled = Match(
            id: "recM1", number: 1, title: "Mexico vs South Africa",
            homeTeamID: "recMEX", awayTeamID: "recRSA",
            kickoff: kickoff, stage: .group, venue: "Estadio Azteca, Mexico City",
            homeScore: nil, awayScore: nil, status: .scheduled
        )
        try await store.replaceMatches([scheduled])

        let finished = Match(
            id: "recM1", number: 1, title: "Mexico vs South Africa",
            homeTeamID: "recMEX", awayTeamID: "recRSA",
            kickoff: kickoff, stage: .group, venue: "Estadio Azteca, Mexico City",
            homeScore: 2, awayScore: 1, status: .finished
        )
        try await store.replaceMatches([finished])

        let matches = try await store.matches()
        #expect(matches == [finished])
    }

    @Test func replaceMatchesTracksLiveMinute() async throws {
        let store = try makeStore()
        let kickoff = Date(timeIntervalSince1970: 1_781_700_000)
        let live = Match(
            id: "recM1", number: 1, title: "Brazil vs Morocco",
            homeTeamID: "recBRA", awayTeamID: "recMAR",
            kickoff: kickoff, stage: .group, venue: "MetLife Stadium, New York",
            homeScore: 1, awayScore: 0, status: .live, minute: "67'"
        )
        try await store.replaceMatches([live])
        #expect(try await store.matches().first?.minute == "67'")

        // Full time clears the clock.
        let finished = Match(
            id: "recM1", number: 1, title: "Brazil vs Morocco",
            homeTeamID: "recBRA", awayTeamID: "recMAR",
            kickoff: kickoff, stage: .group, venue: "MetLife Stadium, New York",
            homeScore: 2, awayScore: 1, status: .finished, minute: nil
        )
        try await store.replaceMatches([finished])
        #expect(try await store.matches().first?.minute == nil)
    }

    @Test func replaceGoalsUpsertsAndPrunes() async throws {
        let store = try makeStore()
        let first = Goal(
            id: "recG1", matchNumber: 2, matchID: "recM2", teamID: "recBRA",
            scorer: "Vinícius Jr.", minute: "23'", type: .goal
        )
        let second = Goal(
            id: "recG2", matchNumber: 2, matchID: "recM2", teamID: "recMAR",
            scorer: "Y. En-Nesyri", minute: "41'", type: .penalty
        )
        try await store.replaceGoals([first, second])
        #expect(try await store.goals().count == 2)

        // A correction removes the disallowed goal and updates the other.
        let corrected = Goal(
            id: "recG1", matchNumber: 2, matchID: "recM2", teamID: "recBRA",
            scorer: "Vinícius Júnior", minute: "23'", type: .goal
        )
        try await store.replaceGoals([corrected])

        let goals = try await store.goals()
        #expect(goals == [corrected])
    }
}
