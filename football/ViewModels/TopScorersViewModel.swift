import Foundation
import Observation
import FootballCore
import FootballManager

@MainActor
@Observable
final class TopScorersViewModel {
    enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private(set) var scorers: [TopScorerRowModel] = []

    private let service: any FootballService

    init(service: any FootballService) {
        self.service = service
    }

    func start() async {
        await loadFromStore()
        await refresh()
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(60))
            await loadFromStore()
        }
    }

    func refresh() async {
        do {
            try await service.refresh()
            await loadFromStore()
        } catch {
            if scorers.isEmpty { phase = .failed(Self.failureMessage) }
        }
    }

    private func loadFromStore() async {
        do {
            async let scorersTask = service.topScorers()
            async let teamsTask = service.teams()
            let (scorers, teams) = try await (scorersTask, teamsTask)
            let teamsByID = Dictionary(teams.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            self.scorers = scorers.map {
                TopScorerRowModel(scorer: $0, team: $0.teamID.flatMap { teamsByID[$0] })
            }
            if !self.scorers.isEmpty { phase = .loaded }
        } catch {
            if scorers.isEmpty { phase = .failed(Self.failureMessage) }
        }
    }

    private static var failureMessage: String {
        String(localized: "Could not load the scorers. Check your connection and try again.")
    }
}

/// One leaderboard row, resolved for display.
struct TopScorerRowModel: Identifiable {
    let id: String
    let rank: Int
    let player: String
    let teamID: String?
    let flag: String
    let teamName: String
    let goals: Int
    let assists: Int
    let penalties: Int

    init(scorer: TopScorer, team: Team?) {
        id = scorer.id
        rank = scorer.rank
        player = scorer.player
        teamID = scorer.teamID
        flag = team?.flag ?? ""
        teamName = team?.name ?? ""
        goals = scorer.goals
        assists = scorer.assists
        penalties = scorer.penalties
    }
}
