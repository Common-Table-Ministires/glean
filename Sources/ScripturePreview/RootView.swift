import SwiftUI
import ScriptureCore

enum Mode: String, CaseIterable, Identifiable {
    case feed = "Feed"
    case stories = "Stories"
    case study = "Study"
    var id: String { rawValue }
}

struct RootView: View {
    @State private var store: ScriptureStore?
    @State private var translation: BibleTranslation = .bsb
    @State private var mode: Mode = .feed
    @StateObject private var readerSettings = ReaderSettings()

    var body: some View {
        VStack(spacing: 0) {
            if let store {
                // All three tabs stay mounted at all times, switching only which one
                // is visible/hit-testable. A `switch` that conditionally instantiates
                // one view per case would tear down and recreate the other two every
                // time, losing whatever reference/scroll/navigation state they held;
                // this keeps Stories' navigation stack and Study's picked passage
                // alive exactly as left, no extra persistence code needed for that.
                ZStack {
                    FeedView(store: store, translation: $translation)
                        .opacity(mode == .feed ? 1 : 0)
                        .allowsHitTesting(mode == .feed)
                    StoryListView(store: store, translation: translation)
                        .opacity(mode == .stories ? 1 : 0)
                        .allowsHitTesting(mode == .stories)
                    StudyView(store: store, translation: translation)
                        .opacity(mode == .study ? 1 : 0)
                        .allowsHitTesting(mode == .study)
                }
            } else {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Picker("Translation", selection: $translation) {
                    ForEach(BibleTranslation.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .help("Translation")

                Button {
                    readerSettings.decreaseFontSize()
                } label: {
                    Image(systemName: "textformat.size.smaller")
                }
                .disabled(readerSettings.fontScale <= ReaderSettings.scaleSteps.first!)
                .help("Smaller text")

                Button {
                    readerSettings.increaseFontSize()
                } label: {
                    Image(systemName: "textformat.size.larger")
                }
                .disabled(readerSettings.fontScale >= ReaderSettings.scaleSteps.last!)
                .help("Larger text")

                Toggle(isOn: $readerSettings.useDyslexicFont) {
                    Image(systemName: "character.book.closed")
                }
                .toggleStyle(.button)
                .help("Dyslexia-friendly font (OpenDyslexic)")
            }
        }
        .safeAreaInset(edge: .bottom) {
            BottomTabBar(mode: $mode)
        }
        .environmentObject(readerSettings)
        .frame(width: 393, height: 852)
        .onAppear {
            guard store == nil else { return }
            if let dbPath = Self.scriptureDatabasePath() {
                store = ScriptureStore(path: dbPath)
            }
        }
    }

    /// Resolve scripture.sqlite without trapping when SPM's Bundle.module is missing
    /// inside a hand-packaged .app (ScripturePreview EXC_BREAKPOINT on Jul 18).
    private static func scriptureDatabasePath() -> String? {
        if let path = Bundle.main.path(forResource: "scripture", ofType: "sqlite") {
            return path
        }
        // Nested SPM resource bundles copied into Contents/Resources/
        if let resourceURL = Bundle.main.resourceURL {
            let candidates = [
                resourceURL.appendingPathComponent("scripture.sqlite"),
                resourceURL.appendingPathComponent("ScriptureApp_ScripturePreview.bundle/Contents/Resources/scripture.sqlite"),
                resourceURL.appendingPathComponent("ScriptureApp_ScripturePreview.bundle/scripture.sqlite"),
            ]
            for url in candidates where FileManager.default.fileExists(atPath: url.path) {
                return url.path
            }
        }
        // Last: SPM Bundle.module (works under `swift run` / Xcode scheme).
        // Access only after main-bundle lookups failed; still can assert if the
        // generated accessor cannot locate its bundle at all — packaging fix above
        // is the real guard for .app launches.
        return Bundle.module.path(forResource: "scripture", ofType: "sqlite")
    }
}

#Preview {
    RootView()
}
