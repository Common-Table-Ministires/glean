import SwiftUI
import ScriptureCore

struct RootView: View {
    @State private var store: ScriptureStore?
    @State private var translation: BibleTranslation = .bsb
    @State private var loadError: String?
    @StateObject private var readerSettings = ReaderSettings()
    @StateObject private var feedPreferences = FeedPreferencesStore()
    @StateObject private var studyNavigator = StudyNavigator()

    var body: some View {
        Group {
            if let store {
                TabView(selection: $studyNavigator.selectedTab) {
                    NavigationStack {
                        FeedView(store: store, translation: $translation)
                    }
                    .tabItem { Label("Feed", systemImage: "square.stack") }
                    .tag(StudyNavigator.Tab.feed)

                    NavigationStack {
                        StudyView(store: store, translation: translation)
                    }
                    .tabItem { Label("Study", systemImage: "highlighter") }
                    .tag(StudyNavigator.Tab.study)

                    StoryListView(store: store, translation: translation)
                        .tabItem { Label("Stories", systemImage: "checklist") }
                        .tag(StudyNavigator.Tab.stories)

                    NavigationStack {
                        SettingsView(translation: $translation)
                    }
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(StudyNavigator.Tab.settings)
                }
            } else if let loadError {
                ContentUnavailableView(
                    "Couldn’t open Scripture",
                    systemImage: "book.closed",
                    description: Text(loadError)
                )
            } else {
                ProgressView("Opening Scripture…")
            }
        }
        .environmentObject(readerSettings)
        .environmentObject(feedPreferences)
        .environmentObject(studyNavigator)
        .appTheme(readerSettings.palette, typography: readerSettings.typography)
        .tint(readerSettings.palette.accent)
        .onAppear(perform: openStoreIfNeeded)
    }

    private func openStoreIfNeeded() {
        guard store == nil, loadError == nil else { return }

        guard let dbPath = Bundle.main.path(forResource: "scripture", ofType: "sqlite") else {
            loadError = "The Scripture database is missing from this install. Try reinstalling Glean from Xcode."
            return
        }

        let opened = ScriptureStore(path: dbPath)
        if opened.allBooks().isEmpty {
            loadError = "Scripture database opened but looks empty. Reinstall the app to restore BSB/KJV."
            return
        }
        store = opened
    }
}

#Preview {
    RootView()
}
