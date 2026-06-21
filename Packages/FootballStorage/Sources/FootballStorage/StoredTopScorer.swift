import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredTopScorer {
    @Attribute(.unique) public var remoteID: String
    public var rank: Int
    public var player: String
    public var teamID: String?
    public var goals: Int
    public var assists: Int
    public var penalties: Int
    public var minutes: Int
    public var photoURL: URL?

    public init(
        remoteID: String,
        rank: Int,
        player: String,
        teamID: String?,
        goals: Int,
        assists: Int,
        penalties: Int,
        minutes: Int,
        photoURL: URL?
    ) {
        self.remoteID = remoteID
        self.rank = rank
        self.player = player
        self.teamID = teamID
        self.goals = goals
        self.assists = assists
        self.penalties = penalties
        self.minutes = minutes
        self.photoURL = photoURL
    }
}

extension StoredTopScorer {
    convenience init(_ s: TopScorer) {
        self.init(
            remoteID: s.id, rank: s.rank, player: s.player, teamID: s.teamID,
            goals: s.goals, assists: s.assists, penalties: s.penalties,
            minutes: s.minutes, photoURL: s.photoURL
        )
    }

    func update(from s: TopScorer) {
        rank = s.rank
        player = s.player
        teamID = s.teamID
        goals = s.goals
        assists = s.assists
        penalties = s.penalties
        minutes = s.minutes
        photoURL = s.photoURL
    }

    var topScorer: TopScorer {
        TopScorer(
            id: remoteID, rank: rank, player: player, teamID: teamID,
            goals: goals, assists: assists, penalties: penalties,
            minutes: minutes, photoURL: photoURL
        )
    }
}
