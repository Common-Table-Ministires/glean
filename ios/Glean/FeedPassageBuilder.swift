import Foundation
import ScriptureCore
import GleanSelection

/// Builds feed cards from formation chunks (or SQLite fallbacks).
///
/// Spec (`content-model.md`): a segment is ~40–120 words — the **whole unit**
/// is what you flip through. Context page may show a little before/after the unit,
/// not the reverse (one tiny verse on the card + giant blob as “context”).
enum FeedPassageBuilder {

    /// Neighbor verses shown on the context page outside the formation unit.
    private static let neighborRadius = 2

    // MARK: - From selection pack

    static func build(
        chunk: ScriptureChunk,
        store: ScriptureStore,
        translation: BibleTranslation
    ) -> FeedPassage {
        let theology = TheologyCatalog.insight(
            chunkID: chunk.id,
            themes: chunk.themes,
            focusHint: chunk.reference
        )

        guard let chapter = chunk.chapter,
              let start = chunk.startVerse,
              let end = chunk.endVerse,
              let bookOrder = bookOrder(named: chunk.book, in: store)
        else {
            return FeedPassage(chunk: chunk, theology: theology)
        }

        let chapterVerses = store.chapterVerses(
            bookOrder: bookOrder,
            chapter: chapter,
            translation: translation
        )
        let unit = chapterVerses.filter { $0.verse >= start && $0.verse <= end }
        guard !unit.isEmpty else {
            return FeedPassage(chunk: chunk, theology: theology)
        }

        return assemble(
            id: chunk.id,
            bookLabel: chunk.displayBook ?? chunk.book,
            chapter: chapter,
            unitVerses: unit,
            chapterVerses: chapterVerses,
            translation: chunk.translation ?? translation.rawValue,
            theology: theology
        )
    }

    // MARK: - From SQLite random / story fallback

    static func build(
        chunk: Chunk,
        translation: BibleTranslation,
        uniqueSuffix: String,
        themes: [Theme] = []
    ) -> FeedPassage {
        let id = "fallback.\(chunk.book).\(chunk.chapter).\(chunk.verseRange.lowerBound).\(uniqueSuffix)"
        let theology = TheologyCatalog.insight(
            chunkID: id,
            themes: themes,
            focusHint: chunk.reference
        )
        guard !chunk.verses.isEmpty else {
            return FeedPassage(
                id: id,
                reference: chunk.reference,
                text: chunk.text,
                verseCount: chunk.verses.count,
                wordCount: chunk.text.split(whereSeparator: \.isWhitespace).count,
                translation: chunk.translation,
                theology: theology
            )
        }
        let ordered = chunk.verses.sorted { $0.verse < $1.verse }
        return assemble(
            id: id,
            bookLabel: chunk.book,
            chapter: chunk.chapter,
            unitVerses: ordered,
            chapterVerses: ordered, // no extra neighbors without full chapter fetch
            translation: chunk.translation,
            theology: theology
        )
    }

    // MARK: - Core assembly

    /// Flip card = **entire formation unit**. Context = a few verses before/after it.
    private static func assemble(
        id: String,
        bookLabel: String,
        chapter: Int,
        unitVerses: [Verse],
        chapterVerses: [Verse],
        translation: String,
        theology: TheologyInsight?
    ) -> FeedPassage {
        let unit = unitVerses.sorted { $0.verse < $1.verse }
        guard let first = unit.first, let last = unit.last else {
            return FeedPassage(
                id: id,
                reference: "\(bookLabel) \(chapter)",
                text: "",
                verseCount: 0,
                wordCount: 0,
                translation: translation,
                theology: theology
            )
        }

        let fullText = unit.map(\.text).joined(separator: " ")
        let rangeRef = rangeReference(book: bookLabel, chapter: chapter, from: first.verse, to: last.verse)

        // Neighbors outside the unit (true “before / after” the segment)
        let before = chapterVerses
            .filter { $0.verse >= first.verse - neighborRadius && $0.verse < first.verse }
            .sorted { $0.verse < $1.verse }
            .map { FeedVerseLine(verse: $0.verse, text: $0.text) }

        let after = chapterVerses
            .filter { $0.verse > last.verse && $0.verse <= last.verse + neighborRadius }
            .sorted { $0.verse < $1.verse }
            .map { FeedVerseLine(verse: $0.verse, text: $0.text) }

        // focusVerse: preferred “anchor” for commentary lookup (first verse of unit)
        return FeedPassage(
            id: id,
            reference: rangeRef,
            focusReference: rangeRef,
            focusText: fullText,
            focusVerse: first.verse,
            contextBefore: before,
            contextAfter: after,
            text: fullText,
            verseCount: unit.count,
            wordCount: fullText.split(whereSeparator: \.isWhitespace).count,
            translation: translation,
            theology: theology
        )
    }

    private static func rangeReference(book: String, chapter: Int, from start: Int, to end: Int) -> String {
        if start == end {
            return "\(book) \(chapter):\(start)"
        }
        return "\(book) \(chapter):\(start)-\(end)"
    }

    private static func bookOrder(named name: String, in store: ScriptureStore) -> Int? {
        store.allBooks().first(where: { $0.name == name })?.bookOrder
    }
}
