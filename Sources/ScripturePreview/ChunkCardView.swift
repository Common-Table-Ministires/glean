import SwiftUI
import ScriptureCore
import GleanSelection

/// Display-only card. Feed maps GleanSelection chunks; Stories map ScriptureCore chunks.
struct ChunkCardView: View {
    let passage: FeedPassage
    @EnvironmentObject var readerSettings: ReaderSettings

    init(passage: FeedPassage) {
        self.passage = passage
    }

    /// Stories/Study path: adapt Core.Chunk at the UI edge only.
    init(chunk: Chunk) {
        self.passage = FeedPassage(
            id: "core.\(chunk.book).\(chunk.chapter).\(chunk.verseRange.lowerBound)-\(chunk.verseRange.upperBound)",
            reference: chunk.reference,
            text: chunk.text,
            verseCount: chunk.verses.count,
            wordCount: chunk.text.split(whereSeparator: \.isWhitespace).count,
            translation: chunk.translation
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(passage.reference.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(.secondary)
            Text(passage.text)
                .font(readerSettings.bodyFont())
                .lineSpacing(readerSettings.bodyFontSize * 0.3)
                .fixedSize(horizontal: false, vertical: true)
            let verseLabel = passage.verseCount == 1 ? "verse" : "verses"
            let meta: String = {
                if passage.verseCount > 0 {
                    return "\(passage.verseCount) \(verseLabel), \(passage.wordCount) words"
                }
                return "\(passage.wordCount) words"
            }()
            Text(meta)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: 560, alignment: .leading)
    }
}
