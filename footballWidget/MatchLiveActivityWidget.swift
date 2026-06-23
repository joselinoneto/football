import ActivityKit
import WidgetKit
import SwiftUI
import FootballCore
import FootballPresentation

/// Lock Screen + Dynamic Island presentation for an in-progress match. The app
/// (`MatchLiveActivityManager`) starts and updates these; this only renders.
struct MatchLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.18))
                .activitySystemActionForegroundColor(Color.pitch)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedTeam(flag: context.attributes.homeFlag,
                                 code: context.attributes.homeCode,
                                 score: context.state.homeScore)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTeam(flag: context.attributes.awayFlag,
                                 code: context.attributes.awayCode,
                                 score: context.state.awayScore)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.minute ?? String(localized: "LIVE"))
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.live)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.venue)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            } compactLeading: {
                // [flag][score] for the home side.
                HStack(spacing: Design.Spacing.xxSmall) {
                    Text(context.attributes.homeFlag.isEmpty ? "⚽️" : context.attributes.homeFlag)
                    Self.compactScore(context.state.homeScore)
                }
            } compactTrailing: {
                // [score][flag] for the away side.
                HStack(spacing: Design.Spacing.xxSmall) {
                    Self.compactScore(context.state.awayScore)
                    Text(context.attributes.awayFlag.isEmpty ? "⚽️" : context.attributes.awayFlag)
                }
            } minimal: {
                Text(Self.scoreText(context.state))
                    .font(.caption2.weight(.bold).monospacedDigit())
                    .foregroundStyle(Color.live)
            }
            .widgetURL(MatchDeepLink.url(matchID: context.attributes.matchID))
            .keylineTint(Color.live)
        }
    }

    @ViewBuilder
    private func expandedTeam(flag: String, code: String, score: Int?) -> some View {
        HStack(spacing: Design.Spacing.small) {
            Text(flag.isEmpty ? "⚽️" : flag).font(.title3)
            Text(code).font(.headline)
            Text("\(score ?? 0)").font(.title3.monospacedDigit().weight(.bold))
        }
    }

    /// A single side's score, styled for the compact Dynamic Island.
    private static func compactScore(_ score: Int?) -> some View {
        Text("\(score ?? 0)")
            .font(.caption2.weight(.bold).monospacedDigit())
            .foregroundStyle(Color.live)
    }

    static func scoreText(_ state: MatchActivityAttributes.ContentState) -> String {
        "\(state.homeScore ?? 0)–\(state.awayScore ?? 0)"
    }
}

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<MatchActivityAttributes>

    var body: some View {
        VStack(spacing: Design.Spacing.medium) {
            HStack(spacing: Design.Spacing.small) {
                Circle()
                    .fill(Color.live)
                    .frame(width: Design.Size.liveDot, height: Design.Size.liveDot)
                Text("LIVE")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.live)
                Spacer()
                if let minute = context.state.minute, !minute.isEmpty {
                    Text(minute)
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color.live)
                }
            }
            HStack(alignment: .center) {
                team(flag: context.attributes.homeFlag, code: context.attributes.homeCode)
                Spacer()
                Text("\(context.state.homeScore ?? 0) – \(context.state.awayScore ?? 0)")
                    .font(.title2.monospacedDigit().weight(.bold))
                Spacer()
                team(flag: context.attributes.awayFlag, code: context.attributes.awayCode)
            }
            Text(context.attributes.venue)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding()
    }

    private func team(flag: String, code: String) -> some View {
        VStack(spacing: Design.Spacing.xxSmall) {
            Text(flag.isEmpty ? "⚽️" : flag).font(.title2)
            Text(code).font(.caption.weight(.semibold))
        }
    }
}
