import Foundation
import FootballCore

struct TeamFields: Decodable, Sendable {
    let name: String
    let localizedName: String?
    let code: String?
    let group: String?
    let flag: String?

    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case localizedName = "Name pt-BR"
        case code = "Code"
        case group = "Group"
        case flag = "Flag"
    }

    /// The fields requested from Airtable for the given locale; localized
    /// fields are only asked for when the locale needs them. The English
    /// fields are always requested as the fallback.
    static func requestedFields(for locale: ContentLocale) -> [String] {
        var fields = ["Name", "Code", "Group", "Flag"]
        if locale == .brazilianPortuguese {
            fields.append("Name pt-BR")
        }
        return fields
    }
}

struct MatchFields: Decodable, Sendable {
    let title: String?
    let localizedTitle: String?
    let number: Int?
    let homeTeam: [String]?
    let awayTeam: [String]?
    let kickoff: Date?
    let stage: String?
    let venue: String?
    let homeScore: Int?
    let awayScore: Int?
    let homePenalties: Int?
    let awayPenalties: Int?
    let status: String?
    let minute: String?
    let winner: [String]?
    let decidedBy: String?

    enum CodingKeys: String, CodingKey {
        case title = "Match"
        case localizedTitle = "Match pt-BR"
        case number = "Match No"
        case homeTeam = "Home Team"
        case awayTeam = "Away Team"
        case kickoff = "Kickoff"
        case stage = "Stage"
        case venue = "Venue"
        case homeScore = "Home Score"
        case awayScore = "Away Score"
        case homePenalties = "Home Pens"
        case awayPenalties = "Away Pens"
        case status = "Status"
        case minute = "Minute"
        case winner = "Winner"
        case decidedBy = "Decided By"
    }

    // "Decided By" is an enum localized client-side (like Stage/Status), so the
    // pt-BR variant isn't requested — one set of fields serves every locale.
    static func requestedFields(for locale: ContentLocale) -> [String] {
        var fields = [
            "Match", "Match No", "Home Team", "Away Team", "Kickoff",
            "Stage", "Venue", "Home Score", "Away Score", "Home Pens",
            "Away Pens", "Status", "Minute", "Winner", "Decided By"
        ]
        if locale == .brazilianPortuguese {
            fields.append("Match pt-BR")
        }
        return fields
    }
}

struct GoalFields: Decodable, Sendable {
    let matchNumber: Int?
    let match: [String]?
    let team: [String]?
    let scorer: String?
    let minute: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case matchNumber = "Match No"
        case match = "Match"
        case team = "Team"
        case scorer = "Scorer"
        case minute = "Minute"
        case type = "Type"
    }

    // Scorer is a proper noun and the type is localized client-side, so no
    // locale-specific columns are needed — the same set serves every locale.
    static func requestedFields() -> [String] {
        ["Match No", "Match", "Team", "Scorer", "Minute", "Type"]
    }
}

extension Team {
    init?(record: AirtableRecord<TeamFields>, locale: ContentLocale) {
        let fields = record.fields
        let name = switch locale {
        case .english: fields.name
        case .brazilianPortuguese: fields.localizedName ?? fields.name
        }
        self.init(
            id: record.id,
            name: name,
            code: fields.code ?? "",
            group: fields.group ?? "",
            flag: fields.flag ?? ""
        )
    }
}

extension Match {
    init?(record: AirtableRecord<MatchFields>, locale: ContentLocale) {
        let fields = record.fields
        // A match without a number or kickoff cannot be scheduled or upserted
        // meaningfully — treat it as malformed and drop it.
        guard let number = fields.number, let kickoff = fields.kickoff else { return nil }
        let title = switch locale {
        case .english: fields.title
        case .brazilianPortuguese: fields.localizedTitle ?? fields.title
        }
        self.init(
            id: record.id,
            number: number,
            title: title ?? "Match \(number)",
            homeTeamID: fields.homeTeam?.first,
            awayTeamID: fields.awayTeam?.first,
            kickoff: kickoff,
            stage: fields.stage.flatMap(Stage.init(rawValue:)) ?? .group,
            venue: fields.venue ?? "",
            homeScore: fields.homeScore,
            awayScore: fields.awayScore,
            status: fields.status.flatMap(MatchStatus.init(rawValue:)) ?? .scheduled,
            minute: fields.minute,
            homePenalties: fields.homePenalties,
            awayPenalties: fields.awayPenalties,
            winnerTeamID: fields.winner?.first,
            decidedBy: fields.decidedBy.flatMap(DecidedBy.init(rawValue:))
        )
    }
}

extension Goal {
    init?(record: AirtableRecord<GoalFields>) {
        let fields = record.fields
        // A goal needs a match, a scorer, and a minute to be meaningful.
        guard let number = fields.matchNumber,
              let scorer = fields.scorer, !scorer.isEmpty,
              let minute = fields.minute else { return nil }
        self.init(
            id: record.id,
            matchNumber: number,
            matchID: fields.match?.first,
            teamID: fields.team?.first,
            scorer: scorer,
            minute: minute,
            type: fields.type.flatMap(GoalType.init(rawValue:)) ?? .goal
        )
    }
}

// MARK: - Standings

struct StandingFields: Decodable, Sendable {
    let group: String?
    let rank: Int?
    let team: [String]?
    let played: Int?
    let win: Int?
    let draw: Int?
    let loss: Int?
    let goalsFor: Int?
    let goalsAgainst: Int?
    let goalDifference: Int?
    let points: Int?
    let form: String?
    let qualification: String?

    enum CodingKeys: String, CodingKey {
        case group = "Group"
        case rank = "Rank"
        case team = "Team"
        case played = "Played"
        case win = "Win"
        case draw = "Draw"
        case loss = "Loss"
        case goalsFor = "Goals For"
        case goalsAgainst = "Goals Against"
        case goalDifference = "Goal Diff"
        case points = "Points"
        case form = "Form"
        case qualification = "Description"
    }

    // Qualification text is localized client-side; the rest is numeric/codes,
    // so one set of fields serves every locale.
    static func requestedFields() -> [String] {
        ["Group", "Rank", "Team", "Played", "Win", "Draw", "Loss",
         "Goals For", "Goals Against", "Goal Diff", "Points", "Form", "Description"]
    }
}

extension Standing {
    init?(record: AirtableRecord<StandingFields>) {
        let f = record.fields
        guard let rank = f.rank else { return nil }
        self.init(
            id: record.id,
            group: f.group ?? "",
            rank: rank,
            teamID: f.team?.first,
            played: f.played ?? 0,
            win: f.win ?? 0,
            draw: f.draw ?? 0,
            loss: f.loss ?? 0,
            goalsFor: f.goalsFor ?? 0,
            goalsAgainst: f.goalsAgainst ?? 0,
            goalDifference: f.goalDifference ?? 0,
            points: f.points ?? 0,
            form: f.form ?? "",
            qualification: (f.qualification?.isEmpty ?? true) ? nil : f.qualification
        )
    }
}

// MARK: - Match Stats

struct MatchStatFields: Decodable, Sendable {
    let matchNumber: Int?
    let match: [String]?
    let team: [String]?
    let possession: String?
    let shotsTotal: Int?
    let shotsOnGoal: Int?
    let shotsOffGoal: Int?
    let blockedShots: Int?
    let shotsInsideBox: Int?
    let shotsOutsideBox: Int?
    let corners: Int?
    let offsides: Int?
    let fouls: Int?
    let yellowCards: Int?
    let redCards: Int?
    let saves: Int?
    let passesTotal: Int?
    let passesAccurate: Int?
    let passesPercent: String?
    let expectedGoals: Double?

    enum CodingKeys: String, CodingKey {
        case matchNumber = "Match No"
        case match = "Match"
        case team = "Team"
        case possession = "Possession"
        case shotsTotal = "Shots Total"
        case shotsOnGoal = "Shots on Goal"
        case shotsOffGoal = "Shots off Goal"
        case blockedShots = "Blocked Shots"
        case shotsInsideBox = "Shots Inside Box"
        case shotsOutsideBox = "Shots Outside Box"
        case corners = "Corners"
        case offsides = "Offsides"
        case fouls = "Fouls"
        case yellowCards = "Yellow Cards"
        case redCards = "Red Cards"
        case saves = "Saves"
        case passesTotal = "Passes Total"
        case passesAccurate = "Passes Accurate"
        case passesPercent = "Passes %"
        case expectedGoals = "Expected Goals"
    }

    static func requestedFields() -> [String] {
        ["Match No", "Match", "Team", "Possession", "Shots Total", "Shots on Goal",
         "Shots off Goal", "Blocked Shots", "Shots Inside Box", "Shots Outside Box",
         "Corners", "Offsides", "Fouls", "Yellow Cards", "Red Cards", "Saves",
         "Passes Total", "Passes Accurate", "Passes %", "Expected Goals"]
    }
}

extension MatchStat {
    init?(record: AirtableRecord<MatchStatFields>) {
        let f = record.fields
        guard let number = f.matchNumber else { return nil }
        self.init(
            id: record.id,
            matchNumber: number,
            matchID: f.match?.first,
            teamID: f.team?.first,
            possession: f.possession,
            shotsTotal: f.shotsTotal,
            shotsOnGoal: f.shotsOnGoal,
            shotsOffGoal: f.shotsOffGoal,
            blockedShots: f.blockedShots,
            shotsInsideBox: f.shotsInsideBox,
            shotsOutsideBox: f.shotsOutsideBox,
            corners: f.corners,
            offsides: f.offsides,
            fouls: f.fouls,
            yellowCards: f.yellowCards,
            redCards: f.redCards,
            saves: f.saves,
            passesTotal: f.passesTotal,
            passesAccurate: f.passesAccurate,
            passesPercent: f.passesPercent,
            expectedGoals: f.expectedGoals
        )
    }
}

// MARK: - Lineups

struct LineupFields: Decodable, Sendable {
    let matchNumber: Int?
    let match: [String]?
    let team: [String]?
    let player: String?
    let number: Int?
    let position: String?
    let grid: String?
    let started: Bool?
    let captain: Bool?
    let rating: Double?
    let minutes: Int?
    let goals: Int?
    let assists: Int?

    enum CodingKeys: String, CodingKey {
        case matchNumber = "Match No"
        case match = "Match"
        case team = "Team"
        case player = "Player"
        case number = "Number"
        case position = "Position"
        case grid = "Grid"
        case started = "Started"
        case captain = "Captain"
        case rating = "Rating"
        case minutes = "Minutes"
        case goals = "Goals"
        case assists = "Assists"
    }

    static func requestedFields() -> [String] {
        ["Match No", "Match", "Team", "Player", "Number", "Position", "Grid",
         "Started", "Captain", "Rating", "Minutes", "Goals", "Assists"]
    }
}

extension LineupEntry {
    init?(record: AirtableRecord<LineupFields>) {
        let f = record.fields
        guard let number = f.matchNumber,
              let player = f.player, !player.isEmpty else { return nil }
        self.init(
            id: record.id,
            matchNumber: number,
            matchID: f.match?.first,
            teamID: f.team?.first,
            player: player,
            number: f.number,
            position: f.position.flatMap(PlayerPosition.init(rawValue:)),
            grid: f.grid,
            started: f.started ?? false,
            captain: f.captain ?? false,
            rating: f.rating,
            minutes: f.minutes,
            goals: f.goals ?? 0,
            assists: f.assists ?? 0
        )
    }
}

// MARK: - Top Scorers

struct TopScorerFields: Decodable, Sendable {
    let rank: Int?
    let player: String?
    let team: [String]?
    let goals: Int?
    let assists: Int?
    let penalties: Int?
    let minutes: Int?
    let photo: String?

    enum CodingKeys: String, CodingKey {
        case rank = "Rank"
        case player = "Player"
        case team = "Team"
        case goals = "Goals"
        case assists = "Assists"
        case penalties = "Penalties"
        case minutes = "Minutes"
        case photo = "Photo"
    }

    static func requestedFields() -> [String] {
        ["Rank", "Player", "Team", "Goals", "Assists", "Penalties", "Minutes", "Photo"]
    }
}

extension TopScorer {
    init?(record: AirtableRecord<TopScorerFields>) {
        let f = record.fields
        guard let rank = f.rank, let player = f.player, !player.isEmpty else { return nil }
        self.init(
            id: record.id,
            rank: rank,
            player: player,
            teamID: f.team?.first,
            goals: f.goals ?? 0,
            assists: f.assists ?? 0,
            penalties: f.penalties ?? 0,
            minutes: f.minutes ?? 0,
            photoURL: f.photo.flatMap(URL.init(string:))
        )
    }
}

// MARK: - Match Events

struct MatchEventFields: Decodable, Sendable {
    let matchNumber: Int?
    let match: [String]?
    let team: [String]?
    let type: String?
    let player: String?
    let player2: String?
    let detail: String?
    let minute: String?

    enum CodingKeys: String, CodingKey {
        case matchNumber = "Match No"
        case match = "Match"
        case team = "Team"
        case type = "Type"
        case player = "Player"
        case player2 = "Player 2"
        case detail = "Detail"
        case minute = "Minute"
    }

    // Type is localized client-side, so one set of fields serves every locale.
    static func requestedFields() -> [String] {
        ["Match No", "Match", "Team", "Type", "Player", "Player 2", "Detail", "Minute"]
    }
}

extension MatchEvent {
    init?(record: AirtableRecord<MatchEventFields>) {
        let f = record.fields
        guard let number = f.matchNumber,
              let type = f.type.flatMap(MatchEventType.init(rawValue:)),
              let minute = f.minute else { return nil }
        self.init(
            id: record.id,
            matchNumber: number,
            matchID: f.match?.first,
            teamID: f.team?.first,
            type: type,
            player: f.player ?? "",
            player2: (f.player2?.isEmpty ?? true) ? nil : f.player2,
            detail: f.detail ?? "",
            minute: minute
        )
    }
}

// MARK: - Squads

struct SquadFields: Decodable, Sendable {
    let team: [String]?
    let player: String?
    let number: Int?
    let position: String?
    let age: Int?
    let photo: String?

    enum CodingKeys: String, CodingKey {
        case team = "Team"
        case player = "Player"
        case number = "Number"
        case position = "Position"
        case age = "Age"
        case photo = "Photo"
    }

    static func requestedFields() -> [String] {
        ["Team", "Player", "Number", "Position", "Age", "Photo"]
    }
}

extension SquadMember {
    init?(record: AirtableRecord<SquadFields>) {
        let f = record.fields
        guard let player = f.player, !player.isEmpty else { return nil }
        self.init(
            id: record.id,
            teamID: f.team?.first,
            player: player,
            number: f.number,
            position: f.position.flatMap(PlayerPosition.init(rawValue:)),
            age: f.age,
            photoURL: f.photo.flatMap(URL.init(string:))
        )
    }
}

// MARK: - Venues

struct VenueFields: Decodable, Sendable {
    let venue: String?
    let externalID: Int?
    let city: String?
    let country: String?
    let capacity: Int?
    let surface: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case venue = "Venue"
        case externalID = "Ext Venue ID"
        case city = "City"
        case country = "Country"
        case capacity = "Capacity"
        case surface = "Surface"
        case image = "Image"
    }

    static func requestedFields() -> [String] {
        ["Venue", "Ext Venue ID", "City", "Country", "Capacity", "Surface", "Image"]
    }
}

extension Venue {
    init?(record: AirtableRecord<VenueFields>) {
        let f = record.fields
        guard let name = f.venue, !name.isEmpty else { return nil }
        self.init(
            id: record.id,
            name: name,
            externalID: f.externalID,
            city: f.city ?? "",
            country: f.country ?? "",
            capacity: f.capacity,
            surface: f.surface ?? "",
            imageURL: f.image.flatMap(URL.init(string:))
        )
    }
}
