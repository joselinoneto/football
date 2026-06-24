import SwiftUI
import FootballCore
import FootballPresentation

/// Standings shown as the "Standings" segment inside the schedule screen.
/// Each group is a custom rounded card so the first and last team rows get the
/// card's rounded corners, and the column header lines up exactly with the
/// values — neither of which a `List` + `NavigationLink` gives us (the system
/// disclosure chevron shifts row content and breaks the alignment).
struct StandingsList: View {
    let viewModel: MatchScheduleViewModel

    private let hInset = Design.Spacing.xxxLarge

    var body: some View {
        content
            // Standings are not on the polling loop; refresh them whenever this
            // section is presented (re-runs each time the section reappears).
            .task { await viewModel.refreshStandings() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.standingsGroups.isEmpty {
            ContentUnavailableView(
                "No Standings",
                systemImage: "tablecells",
                description: Text("Standings aren't available yet.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: Design.Spacing.section) {
                    ForEach(viewModel.standingsGroups) { group in
                        groupBlock(group)
                    }
                }
                .padding(.horizontal)
                .padding(.top, Design.Spacing.large)
                .padding(.bottom, Design.Spacing.screenBottom)
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh() }
        }
    }

    private func groupBlock(_ group: StandingsGroup) -> some View {
        VStack(alignment: .leading, spacing: Design.Spacing.medium) {
            Text(group.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            columnHeader

            VStack(spacing: 0) {
                ForEach(Array(group.rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 {
                        Divider().padding(.leading, hInset)
                    }
                    teamRow(row)
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Design.Radius.card))
        }
    }

    /// Column labels, using the same leading spacers and column widths as the
    /// rows below, so "P / GD / Pts" sit directly above their values.
    private var columnHeader: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Color.clear.frame(width: Design.Size.standingRankColumn, height: 1)
            Color.clear.frame(width: Design.Size.standingFlagColumn, height: 1)
            Text("Team").frame(maxWidth: .infinity, alignment: .leading)
            Text("P").frame(width: Design.Size.standingStatColumn, alignment: .trailing)
            Text("GD").frame(width: Design.Size.standingStatColumn, alignment: .trailing)
            Text("Pts").frame(width: Design.Size.standingPointsColumn, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.tertiary)
        .textCase(.uppercase)
        .padding(.horizontal, hInset)
    }

    @ViewBuilder
    private func teamRow(_ row: StandingRowModel) -> some View {
        if let teamID = row.teamID {
            NavigationLink {
                TeamDetailView(viewModel: viewModel, teamID: teamID)
            } label: {
                StandingRow(row: row, hInset: hInset)
            }
            .buttonStyle(.plain)
        } else {
            StandingRow(row: row, hInset: hInset)
        }
    }
}

private struct StandingRow: View {
    let row: StandingRowModel
    let hInset: CGFloat

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            ZStack {
                if row.qualifies {
                    Capsule().fill(Color.pitch.opacity(0.18))
                }
                Text("\(row.rank)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(row.qualifies ? Color.pitch : .secondary)
            }
            .frame(width: Design.Size.standingRankColumn, height: Design.Size.standingRankColumn)

            Text(row.flag.isEmpty ? "—" : row.flag)
                .frame(width: Design.Size.standingFlagColumn, alignment: .center)

            Text(row.name)
                .font(.subheadline)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(row.played)")
                .frame(width: Design.Size.standingStatColumn, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(row.goalDifference > 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)")
                .frame(width: Design.Size.standingStatColumn, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text("\(row.points)")
                .fontWeight(.semibold)
                .frame(width: Design.Size.standingPointsColumn, alignment: .trailing)
        }
        .font(.subheadline.monospacedDigit())
        .padding(.horizontal, hInset)
        .padding(.vertical, Design.Spacing.large)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: Text {
        var label = "\(row.rank). \(row.name). \(row.points) points, "
            + "\(row.played) played, goal difference \(row.goalDifference)."
        if let qualification = row.qualificationLabel {
            label += " \(qualification)."
        }
        return Text(label)
    }
}

#Preview {
    NavigationStack {
        StandingsList(viewModel: {
            let vm = MatchScheduleViewModel(service: PreviewFootballService())
            Task { await vm.start() }
            return vm
        }())
        .background(AppBackground())
    }
}
