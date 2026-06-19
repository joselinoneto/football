import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredMatchEvent {
    @Attribute(.unique) public var remoteID: String
    public var matchNumber: Int
    public var matchID: String?
    public var teamID: String?
    public var typeRaw: String
    public var player: String
    public var player2: String?
    public var detail: String
    public var minute: String

    public init(
        remoteID: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        typeRaw: String,
        player: String,
        player2: String?,
        detail: String,
        minute: String
    ) {
        self.remoteID = remoteID
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.typeRaw = typeRaw
        self.player = player
        self.player2 = player2
        self.detail = detail
        self.minute = minute
    }
}

extension StoredMatchEvent {
    convenience init(_ e: MatchEvent) {
        self.init(
            remoteID: e.id, matchNumber: e.matchNumber, matchID: e.matchID, teamID: e.teamID,
            typeRaw: e.type.rawValue, player: e.player, player2: e.player2,
            detail: e.detail, minute: e.minute
        )
    }

    func update(from e: MatchEvent) {
        matchNumber = e.matchNumber
        matchID = e.matchID
        teamID = e.teamID
        typeRaw = e.type.rawValue
        player = e.player
        player2 = e.player2
        detail = e.detail
        minute = e.minute
    }

    var matchEvent: MatchEvent {
        MatchEvent(
            id: remoteID, matchNumber: matchNumber, matchID: matchID, teamID: teamID,
            type: MatchEventType(rawValue: typeRaw) ?? .substitution,
            player: player, player2: player2, detail: detail, minute: minute
        )
    }
}
