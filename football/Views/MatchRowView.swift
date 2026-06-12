import SwiftUI
import FootballCore

struct MatchRowView: View {
    let row: MatchRowModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                trailingDetail
            }
            sideLine(row.home, opponentScore: row.away.score)
            sideLine(row.away, opponentScore: row.home.score)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var trailingDetail: some View {
        switch row.status {
        case .live:
            Text("LIVE")
                .font(.caption.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.red, in: Capsule())
                .foregroundStyle(.white)
        case .scheduled:
            Text(row.kickoff, style: .time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        case .finished:
            Text("FT")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func sideLine(_ side: MatchRowModel.Side, opponentScore: Int?) -> some View {
        let won = row.status == .finished
            && (side.score ?? 0) > (opponentScore ?? 0)
        return HStack {
            Text(side.flag.isEmpty ? "•" : side.flag)
                .frame(width: 28)
            Text(side.name)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(side.flag.isEmpty ? .secondary : .primary)
            Spacer()
            if row.showsScore, let score = side.score {
                Text("\(score)")
                    .fontWeight(won ? .semibold : .regular)
                    .monospacedDigit()
            }
        }
    }
}
