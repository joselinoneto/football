import Foundation
import FootballCore
import FootballManager

/// In-memory stand-in for SwiftUI previews — no network, no SwiftData.
final class PreviewFootballService: FootballService {
    func refresh() async throws {}

    func teams() async throws -> [Team] {
        [
            Team(id: "recMEX", name: "Mexico", code: "MEX", group: "A", flag: "🇲🇽"),
            Team(id: "recRSA", name: "South Africa", code: "RSA", group: "A", flag: "🇿🇦"),
            Team(id: "recBRA", name: "Brazil", code: "BRA", group: "C", flag: "🇧🇷"),
            Team(id: "recMAR", name: "Morocco", code: "MAR", group: "C", flag: "🇲🇦")
        ]
    }

    func matches() async throws -> [Match] {
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
                homeScore: 1, awayScore: 1, status: .live
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
}
