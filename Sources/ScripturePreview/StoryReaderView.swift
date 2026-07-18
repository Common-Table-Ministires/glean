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
        VStack(spacing: 4) {
            Text(story.title)
                .font(.headline)
                .padding(.top, 16)
            Spacer()
            if chunks.indices.contains(index) {
                ChunkCardView(chunk: chunks[index])
                Text("Part \(index + 1) of \(chunks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    index -= 1
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(index <= 0)

                Button {
                    index += 1
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .disabled(chunks.isEmpty || index >= chunks.count - 1)
                .keyboardShortcut(.rightArrow, modifiers: [])
            }
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
