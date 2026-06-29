import SwiftUI
import FootballPresentation

/// Settings tab. For now it carries the app's About information, relocated here
/// from the schedule screen's top-right button.
struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Design.Spacing.sectionLarge) {
                ZStack {
                    Circle()
                        .fill(Color.pitch.opacity(Design.Opacity.iconHalo))
                        .frame(width: Design.Size.aboutHalo, height: Design.Size.aboutHalo)
                    Image(systemName: "soccerball.inverse")
                        .font(.system(size: Design.Size.aboutGlyph))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.pitch)
                }
                .padding(.top, Design.Spacing.section)

                VStack(spacing: Design.Spacing.medium) {
                    Text(verbatim: "Football 2026")
                        .font(.largeTitle.bold())
                    Text("about.tagline")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                Text("about.body")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: Design.Spacing.xxLarge) {
                    deniedRow("No ads")
                    deniedRow("No authentication")
                    deniedRow("No tracking")
                    deniedRow("No pink football boots")
                    deniedRow("No soccer")
                    Divider()
                        .padding(.vertical, Design.Spacing.xxSmall)
                    HStack(spacing: Design.Spacing.xLarge) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(Color.pitch)
                        Text("Just football.")
                            .fontWeight(.semibold)
                    }
                }
                .font(.body)
                .padding(Design.Spacing.section)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quinary, in: RoundedRectangle(cornerRadius: Design.Radius.card))
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, Design.Spacing.screenBottom)
        }
    }

    private func deniedRow(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: Design.Spacing.xLarge) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
            Text(text)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .background(AppBackground())
            .navigationTitle("Settings")
    }
}

#Preview("pt-BR") {
    NavigationStack {
        SettingsView()
            .navigationTitle("Settings")
    }
    .environment(\.locale, Locale(identifier: "pt-BR"))
}
