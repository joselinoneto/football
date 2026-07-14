import SwiftUI
import FootballCore
import FootballPresentation

/// A team's roster, grouped by line. Reached by tapping a country name (e.g.
/// from the standings); reads from the shared view model by ID so it reflects
/// refreshes while open, mirroring `MatchDetailView`.
struct TeamDetailView: View {
    let viewModel: MatchScheduleViewModel
    let teamID: String

    var body: some View {
        let team = viewModel.team(for: teamID)
        let matches = viewModel.matches(for: teamID)
        let sections = viewModel.squadSections(for: teamID)

        ScrollView {
            if let team {
                VStack(spacing: Design.Spacing.section) {
                    header(team)
                    if !matches.isEmpty {
                        MatchesSectionCard(matches: matches, viewModel: viewModel)
                    }
                    if sections.isEmpty {
                        Text("The squad hasn't been published yet.")
                            .font(.callout)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Design.Spacing.sectionLarge)
                    } else {
                        ForEach(sections) { section in
                            SquadSectionCard(section: section)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, Design.Spacing.section)
            } else {
                ContentUnavailableView(
                    "Team Unavailable",
                    systemImage: "person.3",
                    description: Text("This team could not be loaded.")
                )
                .padding(.top, Design.Spacing.sectionLarge)
            }
        }
        .background(AppBackground())
        .navigationTitle(team?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func header(_ team: TeamRowModel) -> some View {
        VStack(spacing: Design.Spacing.medium) {
            Text(team.flag.isEmpty ? "—" : team.flag)
                .font(.system(size: 64))
            Text(team.name)
                .font(.title2.weight(.semibold))
            Text(String(localized: "Group \(team.group)") + " · " + team.code)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Design.Spacing.section)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

/// The team's match history: every game it featured in, most-recent first, each
/// tappable through to the full match detail.
private struct MatchesSectionCard: View {
    let matches: [TeamMatchRowModel]
    let viewModel: MatchScheduleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.large) {
            Text("Matches")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                    NavigationLink {
                        MatchDetailView(viewModel: viewModel, matchID: match.id)
                    } label: {
                        TeamMatchRow(match: match)
                    }
                    .buttonStyle(.plain)
                    if index < matches.count - 1 {
                        Divider().padding(.vertical, Design.Spacing.medium)
                    }
                }
            }
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

/// One match on the team page, from that team's perspective: a W/D/L badge, the
/// opponent, the stage and date, and the scoreline (or kickoff time if upcoming).
private struct TeamMatchRow: View {
    let match: TeamMatchRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.large) {
            outcomeBadge
            VStack(alignment: .leading, spacing: Design.Spacing.xxSmall) {
                HStack(spacing: Design.Spacing.medium) {
                    Text(match.opponentFlag.isEmpty ? "—" : match.opponentFlag)
                        .font(.title3)
                    Text(match.opponentName)
                        .font(.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: Design.Spacing.small)
            trailing
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    /// A colored W/D/L badge for played matches; a neutral dot keeps upcoming
    /// fixtures aligned with the rest of the column.
    @ViewBuilder
    private var outcomeBadge: some View {
        if let outcome = match.outcome {
            Text(letter(outcome))
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: Design.Size.outcomeBadge, height: Design.Size.outcomeBadge)
                .background(color(outcome), in: Circle())
        } else {
            Circle()
                .fill(Color(uiColor: .systemGray5))
                .frame(width: Design.Size.outcomeBadge, height: Design.Size.outcomeBadge)
        }
    }

    @ViewBuilder
    private var trailing: some View {
        if let teamScore = match.teamScore, let opponentScore = match.opponentScore {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(teamScore)–\(opponentScore)")
                    .font(.callout.weight(.semibold).monospacedDigit())
                    .foregroundStyle(match.status == .live ? Color.live : .primary)
                if let teamPens = match.teamPenalties, let opponentPens = match.opponentPenalties {
                    Text("(\(teamPens)–\(opponentPens))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text(match.kickoff, format: .dateTime.hour().minute())
                .font(.callout.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    /// Stage and date, e.g. "Final · 14 Jul"; group games drop the stage since
    /// it's the tournament's default phase.
    private var subtitle: String {
        let date = match.kickoff.formatted(.dateTime.day().month(.abbreviated))
        return match.stage == .group ? date : "\(match.stage.displayName) · \(date)"
    }

    private func letter(_ outcome: TeamMatchRowModel.Outcome) -> String {
        switch outcome {
        case .win: String(localized: "outcome.win", defaultValue: "W")
        case .draw: String(localized: "outcome.draw", defaultValue: "D")
        case .loss: String(localized: "outcome.loss", defaultValue: "L")
        }
    }

    private func color(_ outcome: TeamMatchRowModel.Outcome) -> Color {
        switch outcome {
        case .win: Color.pitch
        case .draw: Color(uiColor: .systemGray)
        case .loss: Color(uiColor: .systemRed)
        }
    }

    private var accessibilityLabel: Text {
        let result: String
        switch match.outcome {
        case .win: result = String(localized: "Won")
        case .draw: result = String(localized: "Drew")
        case .loss: result = String(localized: "Lost")
        case nil: result = match.kickoff.formatted(date: .abbreviated, time: .shortened)
        }
        let score = (match.teamScore != nil && match.opponentScore != nil)
            ? " \(match.teamScore!)–\(match.opponentScore!)" : ""
        return Text("\(result) \(match.opponentName)\(score). \(match.stage.displayName).")
    }
}

private struct SquadSectionCard: View {
    let section: SquadLineSection

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.large) {
            Text(section.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: Design.Spacing.xLarge) {
                ForEach(section.members) { member in
                    PlayerRow(member: member)
                }
            }
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

private struct PlayerRow: View {
    let member: SquadRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(member.number.map { "\($0)" } ?? "–")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.squadNumberColumn, alignment: .center)
            Text(member.name)
                .font(.body)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.medium)
            if let age = member.age {
                Text("\(age)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(member.number.map { "Number \($0), \(member.name)" } ?? member.name)
    }
}

#Preview {
    NavigationStack {
        TeamDetailView(
            viewModel: {
                let vm = MatchScheduleViewModel(service: PreviewFootballService())
                Task { await vm.start() }
                return vm
            }(),
            teamID: "recBRA"
        )
    }
}
