import SwiftUI
import ScriptureCore

struct StoryListView: View {
    let store: ScriptureStore
    let translation: BibleTranslation

    // Owns its own stack (rather than sharing one with Feed/Study) so it can stay
    // pushed into a story across tab switches and app relaunches without any other
    // tab's navigation interfering with it.
    @State private var path = NavigationPath()
    @StateObject private var progressStore = ReadingProgressStore()

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Text("Stories")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                List {
                    Section("Old Testament") {
                        ForEach(Story.core.filter { $0.testament == "OT" }) { story in
                            NavigationLink(story.title, value: story)
                        }
                    }
                    Section("New Testament") {
                        ForEach(Story.core.filter { $0.testament == "NT" }) { story in
                            NavigationLink(story.title, value: story)
                        }
                    }
                }
            }
            .navigationDestination(for: Story.self) { story in
                StoryReaderView(store: store, story: story, translation: translation, progressStore: progressStore)
            }
        }
        .onAppear {
            // Cold-launch resume: only fires once, since this view stays mounted for
            // the rest of the session (see RootView). A live in-session tab switch
            // never re-triggers this because the view was never torn down.
            guard path.isEmpty, let lastID = progressStore.lastStoryID,
                  let story = Story.core.first(where: { $0.id == lastID }) else { return }
            path.append(story)
        }
    }
}
