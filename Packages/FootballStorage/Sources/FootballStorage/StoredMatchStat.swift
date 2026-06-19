import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredMatchStat {
    @Attribute(.unique) public var remoteID: String
    public var matchNumber: Int
    public var matchID: String?
    public var teamID: String?
    public var possession: String?
    public var shotsTotal: Int?
    public var shotsOnGoal: Int?
    public var shotsOffGoal: Int?
    public var blockedShots: Int?
    public var shotsInsideBox: Int?
    public var shotsOutsideBox: Int?
    public var corners: Int?
    public var offsides: Int?
    public var fouls: Int?
    public var yellowCards: Int?
    public var redCards: Int?
    public var saves: Int?
    public var passesTotal: Int?
    public var passesAccurate: Int?
    public var passesPercent: String?
    public var expectedGoals: Double?

    public init(
        remoteID: String,
        matchNumber: Int,
        matchID: String?,
        teamID: String?,
        possession: String?,
        shotsTotal: Int?,
        shotsOnGoal: Int?,
        shotsOffGoal: Int?,
        blockedShots: Int?,
        shotsInsideBox: Int?,
        shotsOutsideBox: Int?,
        corners: Int?,
        offsides: Int?,
        fouls: Int?,
        yellowCards: Int?,
        redCards: Int?,
        saves: Int?,
        passesTotal: Int?,
        passesAccurate: Int?,
        passesPercent: String?,
        expectedGoals: Double?
    ) {
        self.remoteID = remoteID
        self.matchNumber = matchNumber
        self.matchID = matchID
        self.teamID = teamID
        self.possession = possession
        self.shotsTotal = shotsTotal
        self.shotsOnGoal = shotsOnGoal
        self.shotsOffGoal = shotsOffGoal
        self.blockedShots = blockedShots
        self.shotsInsideBox = shotsInsideBox
        self.shotsOutsideBox = shotsOutsideBox
        self.corners = corners
        self.offsides = offsides
        self.fouls = fouls
        self.yellowCards = yellowCards
        self.redCards = redCards
        self.saves = saves
        self.passesTotal = passesTotal
        self.passesAccurate = passesAccurate
        self.passesPercent = passesPercent
        self.expectedGoals = expectedGoals
    }
}

extension StoredMatchStat {
    convenience init(_ s: MatchStat) {
        self.init(
            remoteID: s.id, matchNumber: s.matchNumber, matchID: s.matchID, teamID: s.teamID,
            possession: s.possession, shotsTotal: s.shotsTotal, shotsOnGoal: s.shotsOnGoal,
            shotsOffGoal: s.shotsOffGoal, blockedShots: s.blockedShots,
            shotsInsideBox: s.shotsInsideBox, shotsOutsideBox: s.shotsOutsideBox,
            corners: s.corners, offsides: s.offsides, fouls: s.fouls,
            yellowCards: s.yellowCards, redCards: s.redCards, saves: s.saves,
            passesTotal: s.passesTotal, passesAccurate: s.passesAccurate,
            passesPercent: s.passesPercent, expectedGoals: s.expectedGoals
        )
    }

    func update(from s: MatchStat) {
        matchNumber = s.matchNumber
        matchID = s.matchID
        teamID = s.teamID
        possession = s.possession
        shotsTotal = s.shotsTotal
        shotsOnGoal = s.shotsOnGoal
        shotsOffGoal = s.shotsOffGoal
        blockedShots = s.blockedShots
        shotsInsideBox = s.shotsInsideBox
        shotsOutsideBox = s.shotsOutsideBox
        corners = s.corners
        offsides = s.offsides
        fouls = s.fouls
        yellowCards = s.yellowCards
        redCards = s.redCards
        saves = s.saves
        passesTotal = s.passesTotal
        passesAccurate = s.passesAccurate
        passesPercent = s.passesPercent
        expectedGoals = s.expectedGoals
    }

    var matchStat: MatchStat {
        MatchStat(
            id: remoteID, matchNumber: matchNumber, matchID: matchID, teamID: teamID,
            possession: possession, shotsTotal: shotsTotal, shotsOnGoal: shotsOnGoal,
            shotsOffGoal: shotsOffGoal, blockedShots: blockedShots,
            shotsInsideBox: shotsInsideBox, shotsOutsideBox: shotsOutsideBox,
            corners: corners, offsides: offsides, fouls: fouls,
            yellowCards: yellowCards, redCards: redCards, saves: saves,
            passesTotal: passesTotal, passesAccurate: passesAccurate,
            passesPercent: passesPercent, expectedGoals: expectedGoals
        )
    }
}
