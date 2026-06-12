import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Image(systemName: "soccerball.inverse")
                        .font(.system(size: 110))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.tint)
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text(verbatim: "World Cup 2026")
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

                    VStack(alignment: .leading, spacing: 14) {
                        deniedRow("No ads")
                        deniedRow("No authentication")
                        deniedRow("No tracking")
                        deniedRow("No pink football boots")
                        deniedRow("No soccer")
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Just football.")
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.body)
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quinary, in: RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 32)
            }
            .navigationTitle("About")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func deniedRow(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
            Text(text)
        }
    }
}

#Preview {
    AboutView()
}

#Preview("pt-BR") {
    AboutView()
        .environment(\.locale, Locale(identifier: "pt-BR"))
}
