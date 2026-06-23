import Foundation
import FootballCore
import FootballManager

/// In-memory stand-in for SwiftUI previews — no network, no SwiftData.
public final class PreviewFootballService: FootballService {
    public init() {}

    public func refresh() async throws {}

    public func refreshScores() async throws {}

    public func teams() async throws -> [Team] {
        [
            Team(id: "recMEX", name: "Mexico", code: "MEX", group: "A", flag: "🇲🇽"),
            Team(id: "recRSA", name: "South Africa", code: "RSA", group: "A", flag: "🇿🇦"),
            Team(id: "recBRA", name: "Brazil", code: "BRA", group: "C", flag: "🇧🇷"),
            Team(id: "recMAR", name: "Morocco", code: "MAR", group: "C", flag: "🇲🇦")
        ]
    }

    public func matches() async throws -> [Match] {
        let now = Date()
        return [
            Match(
                id: "recM1", number: 1, title: "Mexico vs South Africa",
                homeTeamID: "recMEX", awayTeamID: "recRSA",
                kickoff: now.addingTimeInterval(-3 * 3600),
                stage: .group, venue: "Estadio Azteca, Mexico City",
                homeScore: 2, awayScore: 1, status: .finished
            ),
            Match(
                id: "recM2", number: 2, title: "Brazil vs Morocco",
                homeTeamID: "recBRA", awayTeamID: "recMAR",
                kickoff: now.addingTimeInterval(-1800),
                stage: .group, venue: "MetLife Stadium, New York",
                homeScore: 2, awayScore: 1, status: .live, minute: "67'"
            ),
            Match(
                id: "recM3", number: 104, title: "Winner Match 102 vs Winner Match 103",
                homeTeamID: nil, awayTeamID: nil,
                kickoff: now.addingTimeInterval(36 * 24 * 3600),
                stage: .final, venue: "MetLife Stadium, New York",
                homeScore: nil, awayScore: nil, status: .scheduled
            )
        ]
    }

    public func goals() async throws -> [Goal] {
        [
            Goal(id: "recG1", matchNumber: 1, matchID: "recM1", teamID: "recMEX",
                 scorer: "H. Lozano", minute: "12'", type: .goal),
            Goal(id: "recG2", matchNumber: 1, matchID: "recM1", teamID: "recRSA",
                 scorer: "P. Tau", minute: "34'", type: .penalty),
            Goal(id: "recG3", matchNumber: 1, matchID: "recM1", teamID: "recMEX",
                 scorer: "S. Giménez", minute: "78'", type: .goal),
            Goal(id: "recG4", matchNumber: 2, matchID: "recM2", teamID: "recBRA",
                 scorer: "Vinícius Jr.", minute: "23'", type: .goal),
            Goal(id: "recG5", matchNumber: 2, matchID: "recM2", teamID: "recMAR",
                 scorer: "Y. En-Nesyri", minute: "41'", type: .penalty),
            Goal(id: "recG6", matchNumber: 2, matchID: "recM2", teamID: "recBRA",
                 scorer: "Rodrygo", minute: "67'", type: .goal)
        ]
    }

    public func standings() async throws -> [Standing] {
        [
            Standing(id: "recS1", group: "Group A", rank: 1, teamID: "recMEX",
                     played: 1, win: 1, draw: 0, loss: 0, goalsFor: 2, goalsAgainst: 1,
                     goalDifference: 1, points: 3, form: "W", qualification: "Round of 32"),
            Standing(id: "recS2", group: "Group A", rank: 2, teamID: "recRSA",
                     played: 1, win: 0, draw: 0, loss: 1, goalsFor: 1, goalsAgainst: 2,
                     goalDifference: -1, points: 0, form: "L", qualification: nil)
        ]
    }

    public func matchStats() async throws -> [MatchStat] {
        [
            MatchStat(id: "recST1", matchNumber: 1, matchID: "recM1", teamID: "recMEX",
                      possession: "58%", shotsTotal: 14, shotsOnGoal: 6, shotsOffGoal: 5,
                      blockedShots: 3, shotsInsideBox: 9, shotsOutsideBox: 5, corners: 6,
                      offsides: 2, fouls: 8, yellowCards: 1, redCards: 0, saves: 3,
                      passesTotal: 520, passesAccurate: 460, passesPercent: "88%",
                      expectedGoals: 1.84),
            MatchStat(id: "recST2", matchNumber: 1, matchID: "recM1", teamID: "recRSA",
                      possession: "42%", shotsTotal: 8, shotsOnGoal: 3, shotsOffGoal: 4,
                      blockedShots: 1, shotsInsideBox: 5, shotsOutsideBox: 3, corners: 3,
                      offsides: 1, fouls: 11, yellowCards: 2, redCards: 0, saves: 4,
                      passesTotal: 380, passesAccurate: 300, passesPercent: "79%",
                      expectedGoals: 0.92)
        ]
    }

    public func lineups() async throws -> [LineupEntry] { [] }

    public func topScorers() async throws -> [TopScorer] {
        [
            TopScorer(id: "recTS1", rank: 1, player: "S. Giménez", teamID: "recMEX",
                      goals: 3, assists: 1, penalties: 0, minutes: 270, photoURL: nil),
            TopScorer(id: "recTS2", rank: 2, player: "Vinícius Jr.", teamID: "recBRA",
                      goals: 2, assists: 2, penalties: 0, minutes: 180, photoURL: nil)
        ]
    }

    public func matchEvents() async throws -> [MatchEvent] {
        [
            MatchEvent(id: "recE1", matchNumber: 1, matchID: "recM1", teamID: "recRSA",
                       type: .yellowCard, player: "T. Mokoena", player2: nil,
                       detail: "Yellow Card", minute: "39'"),
            MatchEvent(id: "recE2", matchNumber: 1, matchID: "recM1", teamID: "recMEX",
                       type: .substitution, player: "H. Lozano", player2: "S. Giménez",
                       detail: "Substitution", minute: "61'")
        ]
    }

    public func squads() async throws -> [SquadMember] { [] }

    public func venues() async throws -> [Venue] { [] }
}
