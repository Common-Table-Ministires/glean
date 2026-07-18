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
        VStack {
            Spacer()
            if let chunk = currentChunk {
                ChunkCardView(chunk: chunk)
            } else {
                ProgressView()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button {
                    loadPrevious()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .disabled(historyIndex <= 0)
                .help("Previous passage")

                Button {
                    loadNext()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .help("Next passage")
            }
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
