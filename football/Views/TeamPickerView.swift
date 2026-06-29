import SwiftUI
import FootballCore
import FootballPresentation

/// Picks the favorite team. Each row previews the accent color derived from the
/// team's flag; "Default" clears the favorite and restores the brand green.
struct TeamPickerView: View {
    let teams: [Team]
    let appearance: AppearanceStore

    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    var body: some View {
        List {
            Section {
                Button {
                    appearance.clearFavorite()
                    dismiss()
                } label: {
                    row(flag: nil, name: Text("Default"), swatch: .pitchDefault,
                        selected: appearance.favoriteTeamID == nil)
                }
                .buttonStyle(.plain)
            }

            ForEach(groups, id: \.key) { group in
                Section("Group \(group.key)") {
                    ForEach(group.teams) { team in
                        Button {
                            appearance.setFavorite(team)
                            dismiss()
                        } label: {
                            row(flag: team.flag, name: Text(team.name), swatch: swatch(for: team),
                                selected: appearance.favoriteTeamID == team.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Favorite team")
        .toolbarTitleDisplayMode(.inline)
        .searchable(text: $search)
    }

    private func row(flag: String?, name: Text, swatch: Color, selected: Bool) -> some View {
        HStack(spacing: Design.Spacing.large) {
            if let flag {
                Text(flag).font(.title3)
            } else {
                Image(systemName: "paintpalette")
                    .foregroundStyle(.secondary)
                    .frame(width: 28)
            }
            name.foregroundStyle(.primary)
            Spacer(minLength: Design.Spacing.medium)
            if selected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.pitch)
            }
            Circle()
                .fill(swatch)
                .frame(width: 18, height: 18)
                .overlay(Circle().strokeBorder(.separator, lineWidth: 0.5))
        }
        .contentShape(Rectangle())
    }

    private var filtered: [Team] {
        guard !search.isEmpty else { return teams }
        return teams.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    private var groups: [(key: String, teams: [Team])] {
        Dictionary(grouping: filtered, by: \.group)
            .map { (key: $0.key, teams: $0.value.sorted { $0.name < $1.name }) }
            .sorted { $0.key < $1.key }
    }

    private func swatch(for team: Team) -> Color {
        guard let color = FlagPalette.brandColor(forFlagEmoji: team.flag) else { return .pitchDefault }
        return Color(.sRGB, red: color.light.red, green: color.light.green, blue: color.light.blue, opacity: 1)
    }
}

#Preview {
    NavigationStack {
        TeamPickerView(
            teams: [
                Team(id: "1", name: "Brazil", code: "BRA", group: "C", flag: "🇧🇷"),
                Team(id: "2", name: "Japan", code: "JPN", group: "E", flag: "🇯🇵"),
                Team(id: "3", name: "Argentina", code: "ARG", group: "A", flag: "🇦🇷")
            ],
            appearance: AppearanceStore()
        )
    }
}
