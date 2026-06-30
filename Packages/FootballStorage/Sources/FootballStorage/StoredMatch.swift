import Foundation
import SwiftData
import FootballCore

@Model
public final class StoredMatch {
    @Attribute(.unique) public var remoteID: String
    public var number: Int
    public var title: String
    public var homeTeamID: String?
    public var awayTeamID: String?
    public var kickoff: Date
    public var stageRaw: String
    public var venue: String
    public var homeScore: Int?
    public var awayScore: Int?
    public var statusRaw: String
    public var minute: String?
    // Knockout result detail. New optional attributes — SwiftData migrates
    // existing stores lightweightly (they read back as nil until refreshed).
    public var homePenalties: Int?
    public var awayPenalties: Int?
    public var winnerTeamID: String?
    public var decidedByRaw: String?

    public init(
        remoteID: String,
        number: Int,
        title: String,
        homeTeamID: String?,
        awayTeamID: String?,
        kickoff: Date,
        stageRaw: String,
        venue: String,
        homeScore: Int?,
        awayScore: Int?,
        statusRaw: String,
        minute: String? = nil,
        homePenalties: Int? = nil,
        awayPenalties: Int? = nil,
        winnerTeamID: String? = nil,
        decidedByRaw: String? = nil
    ) {
        self.remoteID = remoteID
        self.number = number
        self.title = title
        self.homeTeamID = homeTeamID
        self.awayTeamID = awayTeamID
        self.kickoff = kickoff
        self.stageRaw = stageRaw
        self.venue = venue
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.statusRaw = statusRaw
        self.minute = minute
        self.homePenalties = homePenalties
        self.awayPenalties = awayPenalties
        self.winnerTeamID = winnerTeamID
        self.decidedByRaw = decidedByRaw
    }
}

extension StoredMatch {
    convenience init(_ match: Match) {
        self.init(
            remoteID: match.id,
            number: match.number,
            title: match.title,
            homeTeamID: match.homeTeamID,
            awayTeamID: match.awayTeamID,
            kickoff: match.kickoff,
            stageRaw: match.stage.rawValue,
            venue: match.venue,
            homeScore: match.homeScore,
            awayScore: match.awayScore,
            statusRaw: match.status.rawValue,
            minute: match.minute,
            homePenalties: match.homePenalties,
            awayPenalties: match.awayPenalties,
            winnerTeamID: match.winnerTeamID,
            decidedByRaw: match.decidedBy?.rawValue
        )
    }

    func update(from match: Match) {
        number = match.number
        title = match.title
        homeTeamID = match.homeTeamID
        awayTeamID = match.awayTeamID
        kickoff = match.kickoff
        stageRaw = match.stage.rawValue
        venue = match.venue
        homeScore = match.homeScore
        awayScore = match.awayScore
        statusRaw = match.status.rawValue
        minute = match.minute
        homePenalties = match.homePenalties
        awayPenalties = match.awayPenalties
        winnerTeamID = match.winnerTeamID
        decidedByRaw = match.decidedBy?.rawValue
    }

    var match: Match {
        Match(
            id: remoteID,
            number: number,
            title: title,
            homeTeamID: homeTeamID,
            awayTeamID: awayTeamID,
            kickoff: kickoff,
            stage: Stage(rawValue: stageRaw) ?? .group,
            venue: venue,
            homeScore: homeScore,
            awayScore: awayScore,
            status: MatchStatus(rawValue: statusRaw) ?? .scheduled,
            minute: minute,
            homePenalties: homePenalties,
            awayPenalties: awayPenalties,
            winnerTeamID: winnerTeamID,
            decidedBy: decidedByRaw.flatMap(DecidedBy.init(rawValue:))
        )
    }
}
