import SwiftUI

struct SettingsScreen: View {
    @Environment(FitStore.self) private var store
    @State private var tapeNote = ""
    @State private var legalPage: LegalPage?

    var body: some View {
        ScreenScaffold {
            ScreenHeader(
                title: AppTheme.displayName,
                subtitle: "Piece, opening, and the call to load or leave it."
            )

            SectionCard(title: "On this phone") {
                DetailRow(label: "App", value: "\(AppTheme.displayName) · \(version)", isProminent: true)
                DetailRow(label: "Pieces", value: "\(store.pieces.count)")
                DetailRow(label: "Stops", value: "\(store.stops.count)")
                DetailRow(label: "Checks", value: "\(store.readings.count)")
                DetailRow(label: "Storage", value: "Stays on this iPhone")
            }

            if !tapeNote.isEmpty {
                SectionCard(title: "Tuesday pickup") {
                    Text(tapeNote)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            SectionCard(title: "About") {
                Text("Measure a piece and the openings on the way out. The app says whether to load it, turn it, take it apart, or leave it.")
                    .font(.body)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                DetailRow(label: "Fit data", value: "On device only")
                DetailRow(label: "Internet", value: "Policies & ads only")
                DetailRow(label: "Camera", value: "Not used")
                DetailRow(label: "Location", value: "Not used")
            }

            SectionCard(title: "Policies") {
                if let privacy = Legal.privacy {
                    Button {
                        legalPage = LegalPage(id: "privacy", url: privacy)
                    } label: {
                        DetailRow(label: "Privacy Policy", value: "Open", isProminent: true)
                    }
                    .buttonStyle(.plain)
                }
                if let terms = Legal.terms {
                    Button {
                        legalPage = LegalPage(id: "terms", url: terms)
                    } label: {
                        DetailRow(label: "Terms of Use", value: "Open", isProminent: true)
                    }
                    .buttonStyle(.plain)
                }
            }

            CTAButton(title: "Delete All Data", systemImage: "trash", emphasis: .secondary) {
                store.deleteAll()
            }
        }
        .navigationTitle("Settings")
        .task { tapeNote = FitWorksheets.report() }
        .sensoryFeedback(.warning, trigger: store.hasCompletedOnboarding)
        .sheet(item: $legalPage) { page in
            SafariPage(url: page.url)
                .ignoresSafeArea()
        }
    }

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}

#Preview {
    NavigationStack { SettingsScreen() }
        .environment(FitStore.preview())
}
