import SwiftUI
import FootballCore

struct MatchRowView: View {
    let row: MatchRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.large) {
            header
            VStack(spacing: Design.Spacing.medium) {
                teamLine(row.home, opponentScore: row.away.score)
                teamLine(row.away, opponentScore: row.home.score)
            }
        }
        .padding(.vertical, Design.Spacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: Header (context + status)

    private var header: some View {
        HStack(spacing: Design.Spacing.small) {
            if row.stage != .group {
                Text(row.stage.displayName)
                    .font(.caption2.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color.pitch)
                Text(verbatim: "·")
                    .foregroundStyle(.tertiary)
            }
            Text(row.venue)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.medium)
            trailingDetail
        }
    }

    @ViewBuilder
    private var trailingDetail: some View {
        switch row.status {
        case .live:
            HStack(spacing: Design.Spacing.small) {
                if let minute = row.minute, !minute.isEmpty {
                    Text(minute)
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.live)
                }
                LiveBadge()
            }
        case .scheduled:
            Text(row.kickoff, style: .time)
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
        case .finished:
            Text("FT")
                .font(.caption2.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Design.Pill.horizontalPadding)
                .padding(.vertical, Design.Pill.verticalPadding)
                .background(.quaternary, in: Capsule())
        }
    }

    private struct LiveBadge: View {
        @State private var pulsing = false

        var body: some View {
            HStack(spacing: Design.Pill.contentSpacing) {
                Circle()
                    .fill(.white)
                    .frame(width: Design.Size.liveDot, height: Design.Size.liveDot)
                    .scaleEffect(pulsing ? Design.Motion.pulseScale : 1)
                    .opacity(pulsing ? Design.Opacity.pulseMin : 1)
                Text("LIVE")
            }
            .font(.caption2.bold())
            .padding(.horizontal, Design.Pill.horizontalPadding)
            .padding(.vertical, Design.Pill.verticalPadding)
            .background(Color.live, in: Capsule())
            .foregroundStyle(.white)
            .onAppear {
                withAnimation(.easeInOut(duration: Design.Motion.pulseDuration).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
        }
    }

    // MARK: Team lines

    private func teamLine(_ side: MatchRowModel.Side, opponentScore: Int?) -> some View {
        let decided = !side.flag.isEmpty
        let won = row.status == .finished && (side.score ?? 0) > (opponentScore ?? 0)
        let lost = row.status == .finished && (side.score ?? 0) < (opponentScore ?? 0)
        let nameColor: Color = decided && !lost ? .primary : .secondary

        return HStack(spacing: Design.Spacing.xLarge) {
            Text(side.flag.isEmpty ? "—" : side.flag)
                .font(.title3)
                .frame(width: Design.Size.flagColumn, alignment: .center)
            Text(side.name)
                .font(.body)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(nameColor)
                .lineLimit(1)
            Spacer(minLength: Design.Spacing.medium)
            if row.showsScore, let score = side.score {
                Text("\(score)")
                    .font(.title2.monospacedDigit())
                    .fontWeight(won ? .bold : .medium)
                    .foregroundStyle(lost ? .secondary : .primary)
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: Accessibility

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
        let detail = row.stage == .group ? row.venue : "\(row.stage.displayName), \(row.venue)"
        return Text("\(describe(row.home)), \(describe(row.away)). \(status). \(detail)")
    }
}
