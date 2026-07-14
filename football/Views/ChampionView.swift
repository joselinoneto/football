import SwiftUI
import FootballCore
import FootballPresentation

/// The tournament's dedicated Champion screen: a golden celebration of the
/// World Cup winner, the Final result, and the goals that decided it. Reached
/// from the Matches tab once the Final is played. Tapping the champion opens
/// their squad, mirroring every other team link in the app.
struct ChampionView: View {
    let viewModel: MatchScheduleViewModel
    let champion: ChampionModel

    var body: some View {
        ScrollView {
            VStack(spacing: Design.Spacing.section) {
                hero
                resultCard
                if !champion.highlights.isEmpty {
                    highlightsCard
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Design.Spacing.section)
        }
        .background(AppBackground())
        .navigationTitle("Champions")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Hero

    /// The lifted-trophy moment: the champion's flag and name, tappable through
    /// to their squad. A faint gold wash over the standard card sets it apart
    /// from every other surface without leaving the app's visual language.
    private var hero: some View {
        NavigationLink {
            TeamDetailView(viewModel: viewModel, teamID: champion.teamID)
        } label: {
            VStack(spacing: Design.Spacing.large) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(Color.gold)
                Text("World Champions")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(2)
                    .foregroundStyle(Color.gold)
                Text(champion.flag.isEmpty ? "🏆" : champion.flag)
                    .font(.system(size: 92))
                HStack(spacing: Design.Spacing.small) {
                    Text(champion.name)
                        .font(.largeTitle.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Design.Spacing.sectionLarge)
            .padding(.horizontal, Design.Spacing.section)
            .background(heroBackground)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("\(champion.name), World Champions"))
        .accessibilityHint(Text("Opens the squad"))
    }

    private var heroBackground: some View {
        RoundedRectangle(cornerRadius: Design.Radius.card)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .overlay {
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .fill(
                        LinearGradient(
                            colors: [Color.gold.opacity(0.22), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: Design.Radius.card)
                    .strokeBorder(Color.gold.opacity(0.35), lineWidth: 1)
            }
    }

    // MARK: Final result

    private var resultCard: some View {
        SectionCard(title: "Final") {
            VStack(spacing: Design.Spacing.medium) {
                resultLine(flag: champion.flag, name: champion.name,
                           score: champion.score, pens: champion.penaltyScore, won: true)
                resultLine(flag: champion.runnerUpFlag, name: champion.runnerUpName,
                           score: champion.runnerUpScore, pens: champion.runnerUpPenaltyScore, won: false)
            }
            if let note = resultNote {
                Text(note)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Text(champion.venue)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func resultLine(flag: String, name: String, score: Int?, pens: Int?, won: Bool) -> some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(flag.isEmpty ? "—" : flag)
                .font(.title2)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            Text(name)
                .font(.body)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(won ? .primary : .secondary)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.medium)
            if let score {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(score)")
                        .font(.title3.monospacedDigit())
                        .fontWeight(won ? .bold : .medium)
                        .foregroundStyle(won ? .primary : .secondary)
                    if let pens {
                        Text("(\(pens))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// The after-extra-time / after-penalties qualifier; nil for a result
    /// settled inside 90 minutes, where the scoreline already says everything.
    private var resultNote: String? {
        guard let decidedBy = champion.decidedBy, decidedBy != .regulation else { return nil }
        return decidedBy.fullTimeNote
    }

    // MARK: Highlights

    private var highlightsCard: some View {
        SectionCard(title: "Highlights") {
            VStack(spacing: Design.Spacing.xLarge) {
                ForEach(champion.highlights) { goal in
                    HighlightRow(goal: goal)
                }
            }
        }
    }
}

// MARK: - Shared section card

/// A titled container matching the match-detail card style, so the Champion
/// screen sits naturally alongside the rest of the app.
private struct SectionCard<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.large) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content
        }
        .padding(Design.Spacing.section)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: Design.Radius.card))
    }
}

// MARK: - One goal in the Final's highlights

private struct HighlightRow: View {
    let goal: GoalRowModel

    var body: some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Text(goal.minute)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: Design.Size.goalMinuteColumn, alignment: .leading)
            Image(systemName: "soccerball")
                .font(.footnote)
                .foregroundStyle(Color.pitch)
            HStack(spacing: Design.Spacing.xSmall) {
                Text(goal.scorer)
                    .font(.body)
                    .lineLimit(1)
                if let tag = goal.type.shortTag, !tag.isEmpty {
                    Text("(\(tag))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: Design.Spacing.medium)
            if !goal.flag.isEmpty {
                Text(goal.flag).font(.title3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(goal.minute), \(goal.scorer)"))
    }
}

#Preview {
    NavigationStack {
        ChampionView(
            viewModel: {
                let vm = MatchScheduleViewModel(service: PreviewFootballService())
                Task { await vm.start() }
                return vm
            }(),
            champion: ChampionModel(
                teamID: "recBRA",
                name: "Brazil",
                flag: "🇧🇷",
                runnerUpName: "Morocco",
                runnerUpFlag: "🇲🇦",
                score: 2,
                runnerUpScore: 1,
                penaltyScore: nil,
                runnerUpPenaltyScore: nil,
                decidedBy: .regulation,
                venue: "MetLife Stadium, New York",
                finalMatchID: "recM3",
                highlights: [
                    GoalRowModel(id: "g1", minute: "31'", scorer: "Vinícius Jr.",
                                 type: .goal, flag: "🇧🇷", isHome: true),
                    GoalRowModel(id: "g2", minute: "58'", scorer: "Y. En-Nesyri",
                                 type: .goal, flag: "🇲🇦", isHome: false),
                    GoalRowModel(id: "g3", minute: "84'", scorer: "Rodrygo",
                                 type: .goal, flag: "🇧🇷", isHome: true)
                ]
            )
        )
    }
}
