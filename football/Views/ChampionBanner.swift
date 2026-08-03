import SwiftUI
import FootballPresentation

/// Compact champions row — flag, gold "Champions" tag, and the winner's name.
/// Shared by the Home schedule and the bracket's Final round, where it sits in
/// a list section linking to the dedicated Champion screen.
struct ChampionBanner: View {
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
