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
    let status: String?

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
        case status = "Status"
    }

    static func requestedFields(for locale: ContentLocale) -> [String] {
        var fields = [
            "Match", "Match No", "Home Team", "Away Team", "Kickoff",
            "Stage", "Venue", "Home Score", "Away Score", "Status"
        ]
        if locale == .brazilianPortuguese {
            fields.append("Match pt-BR")
        }
        return fields
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
            status: fields.status.flatMap(MatchStatus.init(rawValue:)) ?? .scheduled
        )
    }
}
