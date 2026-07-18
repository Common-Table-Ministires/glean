import SwiftUI
import ScriptureCore

struct RootView: View {
    @State private var store: ScriptureStore?
    @State private var translation: BibleTranslation = .bsb
    @StateObject private var readerSettings = ReaderSettings()

    var body: some View {
        Group {
            if let store {
                // Native TabView keeps each tab's view (and its @State) alive when
                // switching, unlike a manual `switch`, so Stories' navigation stack
                // and Study's picked passage survive tab switches for free here,
                // unlike the macOS prototype which needed a manual workaround.
                TabView {
                    NavigationStack {
                        FeedView(store: store, translation: $translation)
                    }
                    .tabItem { Label("Feed", systemImage: "square.stack") }

                    StoryListView(store: store, translation: translation)
                        .tabItem { Label("Stories", systemImage: "books.vertical") }

                    NavigationStack {
                        StudyView(store: store, translation: translation)
                    }
                    .tabItem { Label("Study", systemImage: "highlighter") }

                    NavigationStack {
                        SettingsView(translation: $translation)
                    }
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                }
            } else {
                ProgressView()
            }
        }
        .environmentObject(readerSettings)
        .onAppear {
            if store == nil, let dbPath = Bundle.main.path(forResource: "scripture", ofType: "sqlite") {
                store = ScriptureStore(path: dbPath)
            }
        }
    }
}

#Preview {
    RootView()
}
