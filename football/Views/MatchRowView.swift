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
            LiveBadge()
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

    private struct LiveBadge: View {
        @State private var pulsing = false

        var body: some View {
            HStack(spacing: 4) {
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
                    .opacity(pulsing ? 0.3 : 1)
                Text("LIVE")
            }
            .font(.caption.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.red, in: Capsule())
            .foregroundStyle(.white)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
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
