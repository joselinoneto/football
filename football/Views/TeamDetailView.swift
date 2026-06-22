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
        let sections = viewModel.squadSections(for: teamID)

        ScrollView {
            if let team {
                VStack(spacing: Design.Spacing.section) {
                    header(team)
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
