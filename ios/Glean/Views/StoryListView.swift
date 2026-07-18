import SwiftUI
import ScriptureCore

struct StoryListView: View {
    let store: ScriptureStore
    let translation: BibleTranslation

    @State private var path = NavigationPath()
    @StateObject private var progressStore = ReadingProgressStore()

    var body: some View {
        NavigationStack(path: $path) {
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
            .navigationTitle("Stories")
            .navigationDestination(for: Story.self) { story in
                StoryReaderView(store: store, story: story, translation: translation, progressStore: progressStore)
            }
        }
        .onAppear {
            guard path.isEmpty, let lastID = progressStore.lastStoryID,
                  let story = Story.core.first(where: { $0.id == lastID }) else { return }
            path.append(story)
        }
    }
}
