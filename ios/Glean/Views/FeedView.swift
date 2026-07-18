import SwiftUI
import ScriptureCore

struct FeedView: View {
    let store: ScriptureStore
    @Binding var translation: BibleTranslation

    @State private var history: [Chunk] = []
    @State private var historyIndex = -1

    private var currentChunk: Chunk? {
        history.indices.contains(historyIndex) ? history[historyIndex] : nil
    }

    var body: some View {
        ScrollView {
            VStack {
                if let chunk = currentChunk {
                    ChunkCardView(chunk: chunk)
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                } else {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
        }
        .navigationTitle("Feed")
        .navigationBarTitleDisplayMode(.inline)
        // A .bottomBar toolbar placement here silently fails to render at all
        // when nested inside a TabView tab on this iOS version (confirmed by
        // testing, not assumed); an in-content control avoids depending on
        // toolbar/tab-bar interaction behavior that isn't reliable here.
        .safeAreaInset(edge: .bottom) {
            HStack {
                Button {
                    loadPrevious()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(historyIndex <= 0)

                Spacer()

                Button {
                    loadNext()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.bar)
        }
        .onAppear {
            if history.isEmpty { loadNext() }
        }
        .onChange(of: translation) {
            history.removeAll()
            historyIndex = -1
            loadNext()
        }
    }

    private func loadNext() {
        if historyIndex < history.count - 1 {
            historyIndex += 1
            return
        }
        guard let next = store.randomChunk(translation: translation) else { return }
        history.append(next)
        historyIndex = history.count - 1
    }

    private func loadPrevious() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
    }
}
