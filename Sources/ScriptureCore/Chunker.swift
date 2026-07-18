import Foundation

/// v0 chunking: groups consecutive verses within one chapter until a minimum word
/// count is reached, then cuts. This approximates the paragraph-based approach
/// recommended in spec/content-model.md using verse boundaries as the finest grain
/// available, since the bundled translation data doesn't carry real paragraph
/// markers yet. Genre-specific rules from that spec (epistle connective pull-back,
/// poetry strophes, a soft ceiling as well as a floor) are not implemented in this
/// pass; this exists to have something real to look at and react to.
public enum Chunker {
    public static func chunk(verses: [Verse], minWords: Int = 40) -> [Chunk] {
        var chunks: [Chunk] = []
        var currentBatch: [Verse] = []
        var currentWordCount = 0

        func flush() {
            guard let first = currentBatch.first, let last = currentBatch.last else { return }
            chunks.append(Chunk(
                translation: first.translation,
                book: first.book,
                chapter: first.chapter,
                verseRange: first.verse...last.verse,
                verses: currentBatch
            ))
            currentBatch = []
            currentWordCount = 0
        }

        for verse in verses {
            if let last = currentBatch.last, last.chapter != verse.chapter {
                flush()
            }
            currentBatch.append(verse)
            currentWordCount += verse.text.split(separator: " ").count
            if currentWordCount >= minWords {
                flush()
            }
        }
        flush()
        return chunks
    }
}
