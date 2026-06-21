import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredStanding {
    @Attribute(.unique) public var remoteID: String
    public var groupName: String
    public var rank: Int
    public var teamID: String?
    public var played: Int
    public var win: Int
    public var draw: Int
    public var loss: Int
    public var goalsFor: Int
    public var goalsAgainst: Int
    public var goalDifference: Int
    public var points: Int
    public var form: String
    public var qualification: String?

    public init(
        remoteID: String,
        groupName: String,
        rank: Int,
        teamID: String?,
        played: Int,
        win: Int,
        draw: Int,
        loss: Int,
        goalsFor: Int,
        goalsAgainst: Int,
        goalDifference: Int,
        points: Int,
        form: String,
        qualification: String?
    ) {
        self.remoteID = remoteID
        self.groupName = groupName
        self.rank = rank
        self.teamID = teamID
        self.played = played
        self.win = win
        self.draw = draw
        self.loss = loss
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.goalDifference = goalDifference
        self.points = points
        self.form = form
        self.qualification = qualification
    }
}

extension StoredStanding {
    convenience init(_ s: Standing) {
        self.init(
            remoteID: s.id, groupName: s.group, rank: s.rank, teamID: s.teamID,
            played: s.played, win: s.win, draw: s.draw, loss: s.loss,
            goalsFor: s.goalsFor, goalsAgainst: s.goalsAgainst,
            goalDifference: s.goalDifference, points: s.points,
            form: s.form, qualification: s.qualification
        )
    }

    func update(from s: Standing) {
        groupName = s.group
        rank = s.rank
        teamID = s.teamID
        played = s.played
        win = s.win
        draw = s.draw
        loss = s.loss
        goalsFor = s.goalsFor
        goalsAgainst = s.goalsAgainst
        goalDifference = s.goalDifference
        points = s.points
        form = s.form
        qualification = s.qualification
    }

    var standing: Standing {
        Standing(
            id: remoteID, group: groupName, rank: rank, teamID: teamID,
            played: played, win: win, draw: draw, loss: loss,
            goalsFor: goalsFor, goalsAgainst: goalsAgainst,
            goalDifference: goalDifference, points: points,
            form: form, qualification: qualification
        )
    }
}
