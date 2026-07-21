import SwiftUI
import ScriptureCore
import GleanSelection

struct ChunkCardView: View {
    let passage: FeedPassage
    @EnvironmentObject var readerSettings: ReaderSettings
    @Environment(\.appTheme) private var theme

    init(passage: FeedPassage) {
        self.passage = passage
    }

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
            Text(passage.focusReference.uppercased())
                .font(readerSettings.referenceFont(size: 12))
                .foregroundStyle(theme.secondaryText)
            Text(passage.focusText)
                .font(readerSettings.bodyFont())
                .foregroundStyle(theme.primaryText)
                .lineSpacing(readerSettings.bodyFontSize * 0.3)
                .fixedSize(horizontal: false, vertical: true)
            if passage.hasContext {
                Text(passage.reference)
                    .font(.caption2)
                    .foregroundStyle(theme.tertiaryText)
            }
            let verseLabel = passage.verseCount == 1 ? "verse" : "verses"
            let meta: String = {
                if passage.verseCount > 0 {
                    return "\(passage.verseCount) \(verseLabel), \(passage.wordCount) words"
                }
                return "\(passage.wordCount) words"
            }()
            Text(meta)
                .font(.caption)
                .foregroundStyle(theme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
