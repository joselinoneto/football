import SwiftUI
import FootballCore
import FootballPresentation

/// A compact match row tailored to the watch: a context/status line on top, then
/// the two team lines stacked with flag, name, and score.
struct WatchMatchRowView: View {
    let row: MatchRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            header
            teamLine(row.home, opponentScore: row.away.score)
            teamLine(row.away, opponentScore: row.home.score)
        }
        .padding(.vertical, Design.Spacing.xSmall)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var header: some View {
        HStack(spacing: Design.Spacing.xSmall) {
            Text(row.stage == .group ? row.venueShort : row.stage.displayName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.xSmall)
            trailingStatus
        }
    }

    @ViewBuilder
    private var trailingStatus: some View {
        switch row.status {
        case .live:
            HStack(spacing: Design.Spacing.xSmall) {
                if let minute = row.minute, !minute.isEmpty {
                    Text(minute)
                        .font(.caption2.weight(.bold).monospacedDigit())
                }
                Text("LIVE")
                    .font(.caption2.bold())
            }
            .foregroundStyle(Color.live)
        case .scheduled:
            Text(row.kickoff, style: .time)
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
        case .finished:
            Text("FT")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }

    private func teamLine(_ side: MatchRowModel.Side, opponentScore: Int?) -> some View {
        let decided = !side.flag.isEmpty
        let won = row.didWin(side)
        let lost = row.status == .finished && !won && decided

        return HStack(spacing: Design.Spacing.medium) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.body)
            Text(side.name)
                .font(.body)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(decided && !lost ? .primary : .secondary)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.xSmall)
            if row.showsScore, let score = side.score {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(score)")
                        .font(.title3.monospacedDigit())
                        .fontWeight(won ? .bold : .medium)
                        .foregroundStyle(lost ? .secondary : .primary)
                        .contentTransition(.numericText())
                    if let pens = side.penaltyScore {
                        Text("(\(pens))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var accessibilityLabel: Text {
        func describe(_ side: MatchRowModel.Side) -> String {
            guard row.showsScore, let score = side.score else { return side.name }
            return "\(side.name) \(score)"
        }
        let status: String
        switch row.status {
        case .live: status = String(localized: "Live")
        case .finished: status = String(localized: "Full time")
        case .scheduled: status = row.kickoff.formatted(date: .omitted, time: .shortened)
        }
        return Text("\(describe(row.home)), \(describe(row.away)). \(status)")
    }
}

private extension MatchRowModel {
    /// The venue trimmed to the part before the first comma, so it fits the
    /// narrow watch row (e.g. "MetLife Stadium" from "MetLife Stadium, New York").
    var venueShort: String {
        venue.split(separator: ",", maxSplits: 1).first.map(String.init) ?? venue
    }
}

#Preview {
    List {
        WatchMatchRowView(
            row: MatchRowModel(
                match: Match(
                    id: "p1", number: 2, title: "Brazil vs Morocco",
                    homeTeamID: "BRA", awayTeamID: "MAR",
                    kickoff: .now, stage: .group, venue: "MetLife Stadium, New York",
                    homeScore: 2, awayScore: 1, status: .live, minute: "67'"
                ),
                teamsByID: [
                    "BRA": Team(id: "BRA", name: "Brazil", code: "BRA", group: "C", flag: "🇧🇷"),
                    "MAR": Team(id: "MAR", name: "Morocco", code: "MAR", group: "C", flag: "🇲🇦")
                ]
            )
        )
    }
}
