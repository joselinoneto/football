import SwiftUI
import FootballCore
import FootballPresentation

/// The Matches tab: the knockout phase, one round at a time. Built like the Home
/// schedule — a large title, an inset-grouped list that scrolls under the glass
/// tab bar, and a round selector in the toolbar (the same dropdown pattern as the
/// Home filter). A round's ties are grouped into the bracket pairs whose winners
/// meet in the next round, so the bracket relationship stays visible in a plain
/// vertical list.
struct KnockoutBracketView: View {
    let viewModel: MatchScheduleViewModel

    @State private var selectedStage: Stage?

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
        Group {
            if rounds.isEmpty {
                ContentUnavailableView(
                    "No Knockout Matches",
                    systemImage: "trophy",
                    description: Text("The knockout bracket isn't available yet.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                roundList(currentRound(in: rounds), in: rounds)
            }
        }
        .toolbar {
            if !rounds.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    roundMenu(rounds)
                }
            }
        }
    }

    /// The selected round, falling back to the first available one.
    private func currentRound(in rounds: [BracketRound]) -> BracketRound {
        rounds.first { $0.stage == selectedStage } ?? rounds[0]
    }

    /// The round switcher, as a top-bar dropdown so the list gets the full
    /// screen — the same pattern as the Home filter. The label shows the round.
    private func roundMenu(_ rounds: [BracketRound]) -> some View {
        Menu {
            Picker("Round", selection: roundBinding(rounds)) {
                ForEach(rounds) { round in
                    Text(round.stage.displayName).tag(round.stage)
                }
            }
        } label: {
            HStack(spacing: Design.Spacing.xSmall) {
                Image(systemName: "rectangle.split.3x1")
                Text(currentRound(in: rounds).stage.displayName)
                    .fontWeight(.semibold)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
            }
        }
    }

    private func roundBinding(_ rounds: [BracketRound]) -> Binding<Stage> {
        Binding(
            get: { currentRound(in: rounds).stage },
            set: { newValue in withAnimation(.snappy) { selectedStage = newValue } }
        )
    }

    // MARK: List

    private func roundList(_ round: BracketRound, in rounds: [BracketRound]) -> some View {
        let nextRoundName = round.stage == .final
            ? nil
            : rounds.first { Self.order(after: round.stage) == $0.stage }?.stage.displayName
        return List {
            if round.stage == .final {
                finalSections(round)
            } else {
                ForEach(pairs(of: round)) { pair in
                    Section {
                        tieRow(pair.top)
                        if let bottom = pair.bottom { tieRow(bottom) }
                    } footer: {
                        if let nextRoundName, pair.bottom != nil {
                            Text("Winners meet in the \(nextRoundName)")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private func finalSections(_ round: BracketRound) -> some View {
        // Once the Final is played, crown the winner above the fixtures with a
        // tappable banner into the dedicated Champion screen.
        if let champion = viewModel.champion {
            Section {
                NavigationLink {
                    ChampionView(viewModel: viewModel, champion: champion)
                } label: {
                    ChampionBanner(champion: champion)
                }
                .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
            }
        }
        Section {
            ForEach(round.matches) { tieRow($0) }
        } header: {
            Label("Final", systemImage: "trophy.fill")
                .foregroundStyle(Color.pitch)
        }
        if let thirdPlace {
            Section {
                tieRow(thirdPlace)
            } header: {
                Label("Third place play-off", systemImage: "medal.fill")
            }
        }
    }

    private func tieRow(_ match: MatchRowModel) -> some View {
        NavigationLink {
            MatchDetailView(viewModel: viewModel, matchID: match.id)
        } label: {
            KnockoutRowView(row: match)
        }
        .listRowBackground(Color(uiColor: .secondarySystemGroupedBackground))
    }

    /// Matches grouped into bracket pairs; the last group has a single match
    /// only if the round has an odd count (shouldn't happen in a full bracket).
    private func pairs(of round: BracketRound) -> [BracketPair] {
        stride(from: 0, to: round.matches.count, by: 2).map { index in
            BracketPair(
                top: round.matches[index],
                bottom: index + 1 < round.matches.count ? round.matches[index + 1] : nil
            )
        }
    }

    // MARK: Bracket structure

    private static func order(after stage: Stage) -> Stage? {
        switch stage {
        case .roundOf32: return .roundOf16
        case .roundOf16: return .quarterFinal
        case .quarterFinal: return .semiFinal
        case .semiFinal: return .final
        default: return nil
        }
    }

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

// MARK: - Round / pair models

private struct BracketRound: Identifiable {
    let stage: Stage
    let matches: [MatchRowModel]
    var id: Stage { stage }
}

private struct BracketPair: Identifiable {
    let top: MatchRowModel
    let bottom: MatchRowModel?
    var id: String { top.id }
}

// MARK: - Champion banner (top of the Final round once the trophy is lifted)

private struct ChampionBanner: View {
    let champion: ChampionModel

    var body: some View {
        HStack(spacing: Design.Spacing.large) {
            Text(champion.flag.isEmpty ? "🏆" : champion.flag)
                .font(.largeTitle)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            VStack(alignment: .leading, spacing: Design.Spacing.xxSmall) {
                Text("Champions")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .tracking(1.5)
                    .foregroundStyle(Color.gold)
                Text(champion.name)
                    .font(.title3.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: Design.Spacing.medium)
            Image(systemName: "trophy.fill")
                .font(.title3)
                .foregroundStyle(Color.gold)
        }
        .padding(.vertical, Design.Spacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(champion.name), Champions"))
    }
}

// MARK: - A single tie (one match) row, styled like a Home match row

private struct KnockoutRowView: View {
    let row: MatchRowModel

    private var homeWon: Bool { row.didWin(row.home) }
    private var awayWon: Bool { row.didWin(row.away) }

    var body: some View {
        HStack(spacing: Design.Spacing.large) {
            VStack(spacing: Design.Spacing.medium) {
                teamLine(row.home, won: homeWon)
                teamLine(row.away, won: awayWon)
            }
            trailing
                .frame(width: 56)
        }
        .padding(.vertical, Design.Spacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private func teamLine(_ side: MatchRowModel.Side, won: Bool) -> some View {
        let decided = !side.flag.isEmpty
        return HStack(spacing: Design.Spacing.xLarge) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.title3)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            Text(side.name)
                .font(.body)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(decided ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: Design.Spacing.medium)
            if row.showsScore, let score = side.score {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(score)")
                        .font(.title2.monospacedDigit())
                        .fontWeight(won ? .bold : .medium)
                        .foregroundStyle(won ? .primary : .secondary)
                        .contentTransition(.numericText())
                    // Shootout score in parentheses, e.g. "(5)".
                    if let pens = side.penaltyScore {
                        Text("(\(pens))")
                            .font(.caption2.monospacedDigit())
                            .fontWeight(won ? .semibold : .regular)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    /// Kickoff date/time for upcoming ties, FT for finished — no live treatment.
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
            VStack(spacing: 2) {
                Text("FT")
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Design.Pill.horizontalPadding)
                    .padding(.vertical, Design.Pill.verticalPadding)
                    .background(.quaternary, in: Capsule())
                // "pens" / "AET" qualifier when the tie went beyond 90 minutes.
                if let label = row.decidedBy?.shortLabel, !label.isEmpty {
                    Text(label)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
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
