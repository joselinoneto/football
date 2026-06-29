import SwiftUI
import FootballCore
import FootballPresentation

/// The Matches tab: the knockout phase, one round per screen. Swipe left/right
/// to move through the rounds (Round of 32 → Final); a round's matches are a
/// clean vertical list, grouped into the pairs whose winners meet in the next
/// round so the bracket relationship stays visible without a 2-D canvas.
struct KnockoutBracketView: View {
    let viewModel: MatchScheduleViewModel

    @State private var scrolledPage: Int?

    /// The knockout rounds present in the data, in bracket order. Group and
    /// third-place matches are excluded; a round with no matches yet is dropped.
    /// Each round's matches are ordered by their real bracket position (see
    /// `bracketRanks`), so consecutive pairs share a next-round match.
    private var rounds: [BracketRound] {
        let order: [Stage] = [.roundOf32, .roundOf16, .quarterFinal, .semiFinal, .final]
        let rows = viewModel.days.flatMap(\.rows)
            .filter { $0.stage != .group && $0.stage != .thirdPlace }
        let byNumber = Dictionary(rows.map { ($0.number, $0) }, uniquingKeysWith: { first, _ in first })
        let ranks = Self.bracketRanks(rows: rows, byNumber: byNumber)
        let byStage = Dictionary(grouping: rows, by: \.stage)
        return order.compactMap { stage in
            guard let matches = byStage[stage], !matches.isEmpty else { return nil }
            let ordered = matches.sorted {
                (ranks[$0.number] ?? Int.max, $0.kickoff) < (ranks[$1.number] ?? Int.max, $1.kickoff)
            }
            return BracketRound(stage: stage, matches: ordered)
        }
    }

    /// The third-place play-off (the two losing semi-finalists). It sits outside
    /// the bracket tree, so it's shown alongside the Final rather than as a round.
    private var thirdPlace: MatchRowModel? {
        viewModel.days.flatMap(\.rows).first { $0.stage == .thirdPlace }
    }

    var body: some View {
        let rounds = self.rounds
        if rounds.isEmpty {
            ContentUnavailableView(
                "No Knockout Matches",
                systemImage: "trophy",
                description: Text("The knockout bracket isn't available yet.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Matches")
        } else {
            paged(rounds)
        }
    }

    private func paged(_ rounds: [BracketRound]) -> some View {
        let current = min(max(scrolledPage ?? 0, 0), rounds.count - 1)
        // Horizontal paging ScrollView (not a TabView) so each round is a real
        // scroll view that extends under the Liquid Glass tab bar like the other
        // tabs. The round name rides in the inline nav title and the page dots in
        // the toolbar — both system-managed, so nothing overlaps the content.
        return ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(rounds.enumerated()), id: \.element.id) { index, round in
                    RoundPage(
                        round: round,
                        nextRoundName: index + 1 < rounds.count ? rounds[index + 1].stage.displayName : nil,
                        thirdPlace: round.stage == .final ? thirdPlace : nil,
                        viewModel: viewModel
                    )
                    .containerRelativeFrame([.horizontal, .vertical])
                    .id(index)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledPage)
        .scrollIndicators(.hidden)
        .navigationTitle(rounds[current].stage.displayName)
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PageDots(count: rounds.count, index: current)
            }
        }
    }

    // MARK: Bracket structure

    /// The official FIFA World Cup 2026 knockout bracket, by match number: each
    /// later-round match mapped to the two matches whose winners feed it (home,
    /// away). Fixed by the tournament format regardless of results, and the only
    /// reliable source of the links — the data carries match numbers and teams
    /// but no "feeds-from" field. Verified against the published bracket; the
    /// pairings are deliberately not sequential (e.g. 89 ← 74 & 77, QF 98 ← 93
    /// & 94), which is why ordering by kickoff or by number alone is wrong.
    private static let feederMap: [Int: (home: Int, away: Int)] = [
        // Round of 16 ← Round of 32
        89: (74, 77), 90: (73, 75), 91: (76, 78), 92: (79, 80),
        93: (83, 84), 94: (81, 82), 95: (86, 88), 96: (85, 87),
        // Quarter-finals ← Round of 16
        97: (89, 90), 98: (93, 94), 99: (91, 92), 100: (95, 96),
        // Semi-finals ← Quarter-finals
        101: (97, 98), 102: (99, 100),
        // Final ← Semi-finals
        104: (101, 102),
    ]

    /// Ranks every knockout match by a pre-order walk of the official bracket
    /// tree from the Final, following each match's two feeders (home first, then
    /// away). Sorting a round by this rank yields the true top-to-bottom order,
    /// so consecutive matches pair into the same next-round tie.
    private static func bracketRanks(
        rows: [MatchRowModel],
        byNumber: [Int: MatchRowModel]
    ) -> [Int: Int] {
        let root = rows.first(where: { $0.stage == .final }) ?? rows.max { $0.number < $1.number }
        guard let root else { return [:] }
        var ranks: [Int: Int] = [:]
        var next = 0
        func visit(_ number: Int) {
            guard byNumber[number] != nil, ranks[number] == nil else { return }
            ranks[number] = next
            next += 1
            if let feeders = feederMap[number] {
                visit(feeders.home)
                visit(feeders.away)
            }
        }
        visit(root.number)
        return ranks
    }
}

// MARK: - Round model

private struct BracketRound: Identifiable {
    let stage: Stage
    let matches: [MatchRowModel]
    var id: Stage { stage }
}

// MARK: - Page dots

private struct PageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            ForEach(0..<count, id: \.self) { dot in
                Capsule()
                    .fill(dot == index ? Color.pitch : Color.secondary.opacity(0.3))
                    .frame(width: dot == index ? 18 : 6, height: 6)
            }
        }
        .animation(.snappy, value: index)
    }
}

// MARK: - One round (a page)

private struct RoundPage: View {
    let round: BracketRound
    let nextRoundName: String?
    let thirdPlace: MatchRowModel?
    let viewModel: MatchScheduleViewModel

    /// Matches grouped into bracket pairs; the last group has a single match
    /// only if the round has an odd count (shouldn't happen in a full bracket).
    private var pairs: [(top: MatchRowModel, bottom: MatchRowModel?)] {
        stride(from: 0, to: round.matches.count, by: 2).map { index in
            (round.matches[index], index + 1 < round.matches.count ? round.matches[index + 1] : nil)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Design.Spacing.section) {
                if round.stage == .final, let finalMatch = round.matches.first {
                    finalView(finalMatch)
                } else {
                    ForEach(pairs, id: \.top.id) { pair in
                        PairCard(
                            top: pair.top,
                            bottom: pair.bottom,
                            nextRoundName: nextRoundName,
                            viewModel: viewModel
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, Design.Spacing.medium)
            .padding(.bottom, Design.Spacing.screenBottom)
        }
        .scrollIndicators(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    private func finalView(_ match: MatchRowModel) -> some View {
        VStack(spacing: Design.Spacing.sectionLarge) {
            VStack(spacing: Design.Spacing.section) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.pitch)
                    .padding(.top, Design.Spacing.sectionLarge)
                card(match)
            }

            if let thirdPlace {
                VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                    Label("Third place play-off", systemImage: "medal.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    card(thirdPlace)
                }
            }
        }
    }

    private func card(_ match: MatchRowModel) -> some View {
        TieRow(row: match, viewModel: viewModel)
            .background(
                Color(uiColor: .secondarySystemGroupedBackground),
                in: RoundedRectangle(cornerRadius: Design.Radius.card)
            )
    }
}

// MARK: - A bracket pair (two ties that feed the same next-round match)

private struct PairCard: View {
    let top: MatchRowModel
    let bottom: MatchRowModel?
    let nextRoundName: String?
    let viewModel: MatchScheduleViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let nextRoundName, bottom != nil {
                HStack(spacing: Design.Spacing.xSmall) {
                    Spacer()
                    Text("Winners meet in the \(nextRoundName)")
                        .font(.caption2.weight(.medium))
                    Image(systemName: "arrow.turn.right.up")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
                .padding(.horizontal, Design.Spacing.xLarge)
                .padding(.top, Design.Spacing.large)
                .padding(.bottom, Design.Spacing.xSmall)
            }

            TieRow(row: top, viewModel: viewModel)
            if let bottom {
                Divider().padding(.leading, Design.Spacing.xLarge)
                TieRow(row: bottom, viewModel: viewModel)
            }
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: Design.Radius.card)
        )
    }
}

// MARK: - A single tie (one match), tappable to detail

private struct TieRow: View {
    let row: MatchRowModel
    let viewModel: MatchScheduleViewModel

    private var homeWon: Bool {
        row.status == .finished && (row.home.score ?? 0) > (row.away.score ?? 0)
    }
    private var awayWon: Bool {
        row.status == .finished && (row.away.score ?? 0) > (row.home.score ?? 0)
    }

    var body: some View {
        NavigationLink {
            MatchDetailView(viewModel: viewModel, matchID: row.id)
        } label: {
            HStack(spacing: Design.Spacing.large) {
                VStack(spacing: Design.Spacing.medium) {
                    teamLine(row.home, won: homeWon)
                    teamLine(row.away, won: awayWon)
                }
                trailing
                    .frame(width: 52)
            }
            .padding(.horizontal, Design.Spacing.xLarge)
            .padding(.vertical, Design.Spacing.large)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func teamLine(_ side: MatchRowModel.Side, won: Bool) -> some View {
        let decided = !side.flag.isEmpty
        return HStack(spacing: Design.Spacing.medium) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.title3)
                .frame(width: 28, alignment: .center)
            Text(side.name)
                .font(.body)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(decided ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: Design.Spacing.small)
            if row.showsScore, let score = side.score {
                Text("\(score)")
                    .font(.body.weight(won ? .bold : .medium).monospacedDigit())
                    .foregroundStyle(won ? .primary : .secondary)
            }
        }
    }

    /// Kickoff time for upcoming ties, FT for finished — no live treatment.
    @ViewBuilder
    private var trailing: some View {
        switch row.status {
        case .scheduled:
            VStack(spacing: 1) {
                Text(row.kickoff, format: .dateTime.day().month(.abbreviated))
                Text(row.kickoff, style: .time)
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        case .finished:
            Text("FT")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        case .live:
            EmptyView()
        }
    }

    private var accessibilityLabel: Text {
        func describe(_ side: MatchRowModel.Side) -> String {
            guard row.showsScore, let score = side.score else { return side.name }
            return "\(side.name) \(score)"
        }
        let detail = row.status == .finished
            ? String(localized: "Full time")
            : row.kickoff.formatted(date: .abbreviated, time: .shortened)
        return Text("\(describe(row.home)), \(describe(row.away)). \(row.stage.displayName). \(detail)")
    }
}

#Preview {
    NavigationStack {
        KnockoutBracketView(
            viewModel: {
                let vm = MatchScheduleViewModel(service: PreviewFootballService())
                Task { await vm.start() }
                return vm
            }()
        )
        .background(AppBackground())
        .navigationTitle("Matches")
    }
}
