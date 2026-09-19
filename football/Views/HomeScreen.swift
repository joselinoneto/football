import SwiftUI
import FootballCore
import FootballPresentation

/// Home tab container.
///
/// With a regular-width layout (iPhone Duo open, iPad) it adopts iOS 27.1's
/// `ArrangementView`: the schedule sits in the primary (left) pane and the
/// selected match's detail fills the secondary (right) pane. With a compact
/// width (Duo closed, any single-screen iPhone) it is the regular push stack.
/// The current match survives folding either way: closing the device pushes
/// the selected match; opening it shows that match in the detail pane.
struct HomeScreen: View {
    let viewModel: MatchScheduleViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var selectedMatchID: String?
    @State private var path = NavigationPath()

    var body: some View {
        Group {
            // `ArrangementView` ships with the iOS 27.1 SDK (SwiftUI 8.0.85). The
            // module check keeps the project compiling on Xcode 27.0 / Xcode Cloud.
            #if canImport(SwiftUI, _version: 8.0.85)
            if #available(iOS 27.1, *), sizeClass == .regular {
                arrangement
            } else {
                plainStack
            }
            #else
            plainStack
            #endif
        }
        .onChange(of: sizeClass) { _, newValue in
            if newValue == .regular {
                // Unfolded: the pane shows the selection, so pop the stack.
                path = NavigationPath()
            } else if let id = selectedMatchID {
                // Folded: keep reading the same match, now pushed.
                path = NavigationPath([id])
            }
        }
    }

    #if canImport(SwiftUI, _version: 8.0.85)
    @available(iOS 27.1, *)
    private var arrangement: some View {
        ArrangementView {
            NavigationStack(path: $path) {
                SplitAwareMatchList(viewModel: viewModel, selection: $selectedMatchID)
                    .background(AppBackground())
                    .navigationTitle("Football 2026")
            }
        } secondary: {
            NavigationStack {
                MatchDetailPane(viewModel: viewModel, matchID: selectedMatchID)
                    .background(AppBackground())
            }
        }
        .arrangementViewStyle(.split.axes(.horizontal))
    }
    #endif

    private var plainStack: some View {
        NavigationStack(path: $path) {
            MatchListView(viewModel: viewModel, lastOpened: $selectedMatchID)
                .background(AppBackground())
                .navigationTitle("Football 2026")
        }
    }
}

#if canImport(SwiftUI, _version: 8.0.85)
/// The primary pane. While the arrangement is split, rows select into the
/// secondary pane instead of pushing; if the system ever collapses the split,
/// rows fall back to pushing.
@available(iOS 27.1, *)
private struct SplitAwareMatchList: View {
    let viewModel: MatchScheduleViewModel
    @Binding var selection: String?
    @Environment(\.splitArrangementAxis) private var splitAxis

    private var isSplit: Bool { splitAxis != nil }

    var body: some View {
        MatchListView(viewModel: viewModel, selection: isSplit ? $selection : nil, lastOpened: $selection)
            // When the split first appears with nothing picked, land on the
            // first match of the current filter so the pane isn't empty.
            .onChange(of: isSplit, initial: true) { _, split in
                if split { selectFirstIfNeeded() }
            }
            .onChange(of: viewModel.filteredDays.isEmpty) { _, _ in
                if isSplit { selectFirstIfNeeded() }
            }
    }

    private func selectFirstIfNeeded() {
        guard selection == nil else { return }
        selection = viewModel.filteredDays.first?.rows.first?.id
    }
}
#endif

/// The secondary pane: the selected match, or an invitation to pick one.
private struct MatchDetailPane: View {
    let viewModel: MatchScheduleViewModel
    let matchID: String?

    var body: some View {
        if let matchID {
            MatchDetailView(viewModel: viewModel, matchID: matchID)
                .navigationTitle(title(for: matchID))
                // Reset scroll position and pushed team screens per match.
                .id(matchID)
        } else {
            ContentUnavailableView(
                "Pick a Match",
                systemImage: "soccerball",
                description: Text("Choose a match from the schedule to see its scoreboard, timeline and stats.")
            )
        }
    }

    /// "Spain vs France" — the pt-BR catalog entry uses " x ".
    private func title(for matchID: String) -> Text {
        guard let row = viewModel.detail(for: matchID)?.row else { return Text("") }
        return Text("\(row.home.name) vs \(row.away.name)")
    }
}

#Preview {
    HomeScreen(viewModel: MatchScheduleViewModel(service: PreviewFootballService()))
}
