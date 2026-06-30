import SwiftUI
import FootballCore
import FootballPresentation

/// A symmetric scoreboard row — `flag CODE  score × score  CODE flag` — with big
/// fonts on the scores and initials, and a small status caption (live minute /
/// FT) underneath. Used by the medium and large widgets.
struct WidgetMatchRow: View {
    let match: WidgetMatch

    // A side "lost" when the other side is the recorded winner — works for a
    // level scoreline settled on penalties, not just a higher score.
    private var homeLost: Bool { match.didWin(match.away) }
    private var awayLost: Bool { match.didWin(match.home) }

    var body: some View {
        // Mostly a single big scoreline so many rows fit (the large widget shows
        // a long list); only a live match adds a small minute caption above.
        VStack(spacing: Design.Spacing.xxSmall) {
            if match.status == .live { liveCaption }
            HStack(spacing: Design.Spacing.small) {
                side(flag: match.home.flag, code: match.home.code, lost: homeLost)
                Spacer(minLength: Design.Spacing.xSmall)
                center
                Spacer(minLength: Design.Spacing.xSmall)
                side(flag: match.away.flag, code: match.away.code, lost: awayLost, trailing: true)
            }
        }
    }

    private var liveCaption: some View {
        HStack(spacing: Design.Pill.contentSpacing) {
            Circle()
                .fill(Color.live)
                .frame(width: Design.Size.liveDot, height: Design.Size.liveDot)
            Text(liveLabel)
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(Color.live)
            Spacer(minLength: 0)
        }
    }

    /// Flag + initials. Leading side reads flag→code; trailing side mirrors to
    /// code→flag so both flags sit on the outer edges.
    private func side(flag: String, code: String, lost: Bool, trailing: Bool = false) -> some View {
        let flagView = Text(flag.isEmpty ? "—" : flag)
            .font(.title2)
        let codeView = Text(code)
            .font(.title3.weight(.heavy))
            .foregroundStyle(lost ? .secondary : .primary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        return HStack(spacing: Design.Spacing.xSmall) {
            if trailing {
                codeView
                flagView
            } else {
                flagView
                codeView
            }
        }
    }

    @ViewBuilder
    private var center: some View {
        switch match.status {
        case .scheduled:
            Text(match.kickoff, style: .time)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        case .live, .finished:
            HStack(spacing: Design.Spacing.xSmall) {
                score(match.home.score, pens: match.home.penaltyScore, dim: homeLost)
                Text(verbatim: "×")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                score(match.away.score, pens: match.away.penaltyScore, dim: awayLost)
            }
        }
    }

    private func score(_ value: Int?, pens: Int?, dim: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text("\(value ?? 0)")
                .font(.title.weight(.bold).monospacedDigit())
                .foregroundStyle(match.status == .live ? Color.live : (dim ? .secondary : .primary))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            // Shootout score, e.g. "(5)" — kept small so the row still fits.
            if let pens {
                Text("(\(pens))")
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var liveLabel: String {
        if let minute = match.minute, !minute.isEmpty { return minute }
        return String(localized: "LIVE")
    }
}

/// Trailing status used by the small widget: live minute + dot, kickoff time, or FT.
struct WidgetStatusBadge: View {
    let match: WidgetMatch

    var body: some View {
        switch match.status {
        case .live:
            HStack(spacing: Design.Pill.contentSpacing) {
                Circle()
                    .fill(Color.live)
                    .frame(width: Design.Size.liveDot, height: Design.Size.liveDot)
                if let minute = match.minute, !minute.isEmpty {
                    Text(minute)
                        .font(.caption2.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.live)
                } else {
                    Text("LIVE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.live)
                }
            }
        case .scheduled:
            Text(match.kickoff, style: .time)
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
        case .finished:
            let label = match.decidedBy?.shortLabel ?? ""
            Text(label.isEmpty ? "FT" : "FT · \(label)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
}
