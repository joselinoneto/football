import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredLineupEntry {
    @Attribute(.unique) public var remoteID: String
    public var matchNumber: Int
    public var matchID: String?
    public var teamID: String?
    public var player: String
    public var number: Int?
    public var positionRaw: String?
    public var grid: String?
    public var started: Bool
    public var captain: Bool
    public var rating: Double?
    public var minutes: Int?
    public var goals: Int
    public var assists: Int

    public init(
        remoteID: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        player: String,
        number: Int?,
        positionRaw: String?,
        grid: String?,
        started: Bool,
        captain: Bool,
        rating: Double?,
        minutes: Int?,
        goals: Int,
        assists: Int
    ) {
        self.remoteID = remoteID
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.player = player
        self.number = number
        self.positionRaw = positionRaw
        self.grid = grid
        self.started = started
        self.captain = captain
        self.rating = rating
        self.minutes = minutes
        self.goals = goals
        self.assists = assists
    }
}

extension StoredLineupEntry {
    convenience init(_ e: LineupEntry) {
        self.init(
            remoteID: e.id, matchNumber: e.matchNumber, matchID: e.matchID, teamID: e.teamID,
            player: e.player, number: e.number, positionRaw: e.position?.rawValue, grid: e.grid,
            started: e.started, captain: e.captain, rating: e.rating, minutes: e.minutes,
            goals: e.goals, assists: e.assists
        )
    }

    func update(from e: LineupEntry) {
        matchNumber = e.matchNumber
        matchID = e.matchID
        teamID = e.teamID
        player = e.player
        number = e.number
        positionRaw = e.position?.rawValue
        grid = e.grid
        started = e.started
        captain = e.captain
        rating = e.rating
        minutes = e.minutes
        goals = e.goals
        assists = e.assists
    }

    var lineupEntry: LineupEntry {
        LineupEntry(
            id: remoteID, matchNumber: matchNumber, matchID: matchID, teamID: teamID,
            player: player, number: number,
            position: positionRaw.flatMap(PlayerPosition.init(rawValue:)), grid: grid,
            started: started, captain: captain, rating: rating, minutes: minutes,
            goals: goals, assists: assists
        )
    }
}
