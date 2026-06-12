import Foundation
import Testing
import FootballCore
@testable import FootballAPI

@Suite struct DecodingTests {
    @Test func decodesMatchPage() throws {
        let json = """
        {
            "records": [
                {
                    "id": "rec0bcZEKAQHqjIcb",
                    "createdTime": "2026-06-12T18:25:00.000Z",
                    "fields": {
                        "Stage": "Group",
                        "Match No": 20,
                        "Away Team": ["recHD7Gi2GI8R2CFI"],
                        "Venue": "San Francisco Bay Area Stadium",
                        "Home Team": ["recAE4Jf3Bm3DP8GQ"],
                        "Kickoff": "2026-06-17T04:00:00.000Z",
                        "Status": "Scheduled",
                        "Match": "Austria vs Jordan"
                    }
                },
                {
                    "id": "recFinal",
                    "createdTime": "2026-06-12T18:25:00.000Z",
                    "fields": {
                        "Stage": "Final",
                        "Match No": 104,
                        "Kickoff": "2026-07-19T19:00:00Z",
                        "Match": "Winner Match 102 vs Winner Match 103"
                    }
                }
            ],
            "offset": "itrXXX/recYYY"
        }
        """
        let page = try AirtableTransport.decoder.decode(
            AirtablePage<MatchFields>.self,
            from: Data(json.utf8)
        )
        #expect(page.offset == "itrXXX/recYYY")
        #expect(page.records.count == 2)

        let matches = page.records.compactMap { Match(record: $0, locale: .english) }
        #expect(matches.count == 2)

        let group = try #require(matches.first { $0.number == 20 })
        #expect(group.homeTeamID == "recAE4Jf3Bm3DP8GQ")
        #expect(group.awayTeamID == "recHD7Gi2GI8R2CFI")
        #expect(group.stage == .group)
        #expect(group.status == .scheduled)
        #expect(group.homeScore == nil)
        #expect(group.titleSides?.home == "Austria")

        let final = try #require(matches.first { $0.number == 104 })
        #expect(final.stage == .final)
        #expect(final.homeTeamID == nil)
        #expect(final.titleSides?.away == "Winner Match 103")
    }

    @Test func decodesTeamPage() throws {
        let json = """
        {
            "records": [
                {
                    "id": "rec2EdEkFBCdYwk3N",
                    "createdTime": "2026-06-12T18:24:57.000Z",
                    "fields": {
                        "Group": "H",
                        "Code": "ESP",
                        "Matches": ["recxlRAiBodYIXYr4"],
                        "Name": "Spain",
                        "Flag": "🇪🇸"
                    }
                }
            ]
        }
        """
        let page = try AirtableTransport.decoder.decode(
            AirtablePage<TeamFields>.self,
            from: Data(json.utf8)
        )
        #expect(page.offset == nil)

        let team = try #require(page.records.compactMap { Team(record: $0, locale: .english) }.first)
        #expect(team.id == "rec2EdEkFBCdYwk3N")
        #expect(team.name == "Spain")
        #expect(team.code == "ESP")
        #expect(team.group == "H")
        #expect(team.flag == "🇪🇸")
    }

    @Test func dropsMalformedMatches() throws {
        let json = """
        {
            "records": [
                {
                    "id": "recNoKickoff",
                    "createdTime": "2026-06-12T18:25:00.000Z",
                    "fields": { "Match No": 1, "Match": "A vs B" }
                }
            ]
        }
        """
        let page = try AirtableTransport.decoder.decode(
            AirtablePage<MatchFields>.self,
            from: Data(json.utf8)
        )
        #expect(page.records.compactMap { Match(record: $0, locale: .english) }.isEmpty)
    }
}

@Suite struct LocalizationTests {
    @Test func teamPrefersLocalizedNameAndFallsBack() throws {
        let json = """
        {
            "records": [
                {
                    "id": "recGER",
                    "createdTime": "2026-06-12T18:24:57.000Z",
                    "fields": {
                        "Group": "E",
                        "Code": "GER",
                        "Name": "Germany",
                        "Name pt-BR": "Alemanha",
                        "Flag": "🇩🇪"
                    }
                },
                {
                    "id": "recBRA",
                    "createdTime": "2026-06-12T18:24:57.000Z",
                    "fields": {
                        "Group": "C",
                        "Code": "BRA",
                        "Name": "Brazil",
                        "Flag": "🇧🇷"
                    }
                }
            ]
        }
        """
        let page = try AirtableTransport.decoder.decode(
            AirtablePage<TeamFields>.self,
            from: Data(json.utf8)
        )

        let portuguese = page.records.compactMap { Team(record: $0, locale: .brazilianPortuguese) }
        #expect(portuguese.first { $0.code == "GER" }?.name == "Alemanha")
        // Missing translation falls back to English.
        #expect(portuguese.first { $0.code == "BRA" }?.name == "Brazil")

        let english = page.records.compactMap { Team(record: $0, locale: .english) }
        #expect(english.first { $0.code == "GER" }?.name == "Germany")
    }

    @Test func matchPrefersLocalizedTitleAndParsesBrazilianSeparator() throws {
        let json = """
        {
            "records": [
                {
                    "id": "recM1",
                    "createdTime": "2026-06-12T18:25:00.000Z",
                    "fields": {
                        "Stage": "Group",
                        "Match No": 7,
                        "Kickoff": "2026-06-13T19:00:00.000Z",
                        "Status": "Scheduled",
                        "Match": "Brazil vs Morocco",
                        "Match pt-BR": "Brasil x Marrocos"
                    }
                }
            ]
        }
        """
        let page = try AirtableTransport.decoder.decode(
            AirtablePage<MatchFields>.self,
            from: Data(json.utf8)
        )

        let match = try #require(page.records.compactMap { Match(record: $0, locale: .brazilianPortuguese) }.first)
        #expect(match.title == "Brasil x Marrocos")
        #expect(match.titleSides?.home == "Brasil")
        #expect(match.titleSides?.away == "Marrocos")
    }

    @Test func requestedFieldsIncludeLocalizedColumnsOnlyForPortuguese() {
        #expect(!TeamFields.requestedFields(for: .english).contains("Name pt-BR"))
        #expect(TeamFields.requestedFields(for: .brazilianPortuguese).contains("Name pt-BR"))
        #expect(!MatchFields.requestedFields(for: .english).contains("Match pt-BR"))
        #expect(MatchFields.requestedFields(for: .brazilianPortuguese).contains("Match pt-BR"))
        // English fields are always requested as the fallback.
        #expect(TeamFields.requestedFields(for: .brazilianPortuguese).contains("Name"))
        #expect(MatchFields.requestedFields(for: .brazilianPortuguese).contains("Match"))
    }
}
