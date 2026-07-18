import SwiftUI
import ScriptureCore

struct StoryReaderView: View {
    let store: ScriptureStore
    let story: Story
    let translation: BibleTranslation
    @ObservedObject var progressStore: ReadingProgressStore

    @State private var chunks: [Chunk] = []
    @State private var index = 0

    var body: some View {
        ScrollView {
            VStack {
                if chunks.indices.contains(index) {
                    ChunkCardView(chunk: chunks[index])
                        .padding(.horizontal, 20)
                        .padding(.top, 30)
                    Text("Part \(index + 1) of \(chunks.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        // Same .bottomBar-inside-TabView rendering issue as FeedView; see the
        // comment there.
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    index -= 1
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(index <= 0)

                Spacer()

                Button {
                    index += 1
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(chunks.isEmpty || index >= chunks.count - 1)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.bar)
        }
        .onAppear {
            chunks = store.chunks(for: story, translation: translation)
            index = min(progressStore.index(for: story.id), max(chunks.count - 1, 0))
            progressStore.setLastStoryID(story.id)
        }
        .onChange(of: index) {
            progressStore.setIndex(index, for: story.id)
        }
    }
}
