import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredGoal {
    @Attribute(.unique) public var remoteID: String
    public var matchNumber: Int
    public var matchID: String?
    public var teamID: String?
    public var scorer: String
    public var minute: String
    public var typeRaw: String

    public init(
        remoteID: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        scorer: String,
        minute: String,
        typeRaw: String
    ) {
        self.remoteID = remoteID
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.scorer = scorer
        self.minute = minute
        self.typeRaw = typeRaw
    }
}

extension StoredGoal {
    convenience init(_ goal: Goal) {
        self.init(
            remoteID: goal.id,
            matchNumber: goal.matchNumber,
            matchID: goal.matchID,
            teamID: goal.teamID,
            scorer: goal.scorer,
            minute: goal.minute,
            typeRaw: goal.type.rawValue
        )
    }

    func update(from goal: Goal) {
        matchNumber = goal.matchNumber
        matchID = goal.matchID
        teamID = goal.teamID
        scorer = goal.scorer
        minute = goal.minute
        typeRaw = goal.type.rawValue
    }

    var goal: Goal {
        Goal(
            id: remoteID,
            matchNumber: matchNumber,
            matchID: matchID,
            teamID: teamID,
            scorer: scorer,
            minute: minute,
            type: GoalType(rawValue: typeRaw) ?? .goal
        )
    }
}
