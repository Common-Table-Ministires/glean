import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

public final class ScriptureStore: @unchecked Sendable {
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "org.commontableministries.scripturecore")

    public init(path: String) {
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            assertionFailure("failed to open scripture.sqlite at \(path)")
            db = nil
        }
    }

    /// Picks a random chapter, chunks it, and returns one random chunk from that chapter.
    /// Placeholder selection strategy: spec/feed-algorithm.md hasn't been drafted yet, so
    /// this is pure random rather than weighted or reading-history aware.
    public func randomChunk(translation: BibleTranslation) -> Chunk? {
        queue.sync {
            guard let (bookOrder, chapter) = randomBookChapter(translation: translation) else { return nil }
            let verses = versesInChapter(translation: translation, bookOrder: bookOrder, chapter: chapter)
            let chunks = Chunker.chunk(verses: verses)
            return chunks.randomElement()
        }
    }

    private func randomBookChapter(translation: BibleTranslation) -> (bookOrder: Int, chapter: Int)? {
        let sql = """
            SELECT book_order, chapter FROM verses
            WHERE translation = ?
            GROUP BY book_order, chapter
            ORDER BY RANDOM() LIMIT 1
            """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(statement, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(statement) == SQLITE_ROW else { return nil }
        return (Int(sqlite3_column_int(statement, 0)), Int(sqlite3_column_int(statement, 1)))
    }

    /// Fetches every verse in a story's range, in order, and chunks it the same way
    /// the random feed does. Assumes the story is a single-book range (true of every
    /// entry in Story.core today); a cross-book story would need this query rewritten
    /// to compare book_order as part of the range instead of holding it fixed.
    public func chunks(for story: Story, translation: BibleTranslation) -> [Chunk] {
        queue.sync {
            let verses = versesInRange(translation: translation, story: story)
            return Chunker.chunk(verses: verses)
        }
    }

    private func versesInRange(translation: BibleTranslation, story: Story) -> [Verse] {
        let sql = """
            SELECT book, chapter, verse, text FROM verses
            WHERE translation = ? AND book_order = ?
            AND (chapter > ? OR (chapter = ? AND verse >= ?))
            AND (chapter < ? OR (chapter = ? AND verse <= ?))
            ORDER BY chapter, verse
            """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(statement, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(story.bookOrder))
        sqlite3_bind_int(statement, 3, Int32(story.startChapter))
        sqlite3_bind_int(statement, 4, Int32(story.startChapter))
        sqlite3_bind_int(statement, 5, Int32(story.startVerse))
        sqlite3_bind_int(statement, 6, Int32(story.endChapter))
        sqlite3_bind_int(statement, 7, Int32(story.endChapter))
        sqlite3_bind_int(statement, 8, Int32(story.endVerse))

        var results: [Verse] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let book = String(cString: sqlite3_column_text(statement, 0))
            let chapterNum = Int(sqlite3_column_int(statement, 1))
            let verseNum = Int(sqlite3_column_int(statement, 2))
            let text = String(cString: sqlite3_column_text(statement, 3))
            results.append(Verse(
                translation: translation.rawValue,
                book: book,
                bookOrder: story.bookOrder,
                chapter: chapterNum,
                verse: verseNum,
                text: text
            ))
        }
        return results
    }

    /// Full book list for a book/chapter/verse picker. Books aren't translation-specific
    /// (both bundled translations share the same 66-book structure), so no translation
    /// parameter is needed.
    public func allBooks() -> [BookInfo] {
        queue.sync {
            let sql = "SELECT book_order, name, testament, genre FROM books ORDER BY book_order"
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
            var results: [BookInfo] = []
            while sqlite3_step(statement) == SQLITE_ROW {
                results.append(BookInfo(
                    bookOrder: Int(sqlite3_column_int(statement, 0)),
                    name: String(cString: sqlite3_column_text(statement, 1)),
                    testament: String(cString: sqlite3_column_text(statement, 2)),
                    genre: String(cString: sqlite3_column_text(statement, 3))
                ))
            }
            return results
        }
    }

    public func chapterCount(bookOrder: Int, translation: BibleTranslation) -> Int {
        queue.sync {
            let sql = "SELECT MAX(chapter) FROM verses WHERE translation = ? AND book_order = ?"
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return 0 }
            sqlite3_bind_text(statement, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(bookOrder))
            guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
            return Int(sqlite3_column_int(statement, 0))
        }
    }

    public func verseCount(bookOrder: Int, chapter: Int, translation: BibleTranslation) -> Int {
        queue.sync {
            let sql = "SELECT MAX(verse) FROM verses WHERE translation = ? AND book_order = ? AND chapter = ?"
            var statement: OpaquePointer?
            defer { sqlite3_finalize(statement) }
            guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return 0 }
            sqlite3_bind_text(statement, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(statement, 2, Int32(bookOrder))
            sqlite3_bind_int(statement, 3, Int32(chapter))
            guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
            return Int(sqlite3_column_int(statement, 0))
        }
    }

    /// Full chapter text, unchunked, for direct book/chapter/verse lookup and study
    /// (as opposed to randomChunk/chunks(for:), which serve the algorithmic feed and
    /// curated stories through Chunker). Reading a whole chapter in its natural form
    /// is the right shape for "I picked this reference on purpose," not a feed chunk.
    public func chapterVerses(bookOrder: Int, chapter: Int, translation: BibleTranslation) -> [Verse] {
        queue.sync {
            versesInChapter(translation: translation, bookOrder: bookOrder, chapter: chapter)
        }
    }

    private func versesInChapter(translation: BibleTranslation, bookOrder: Int, chapter: Int) -> [Verse] {
        let sql = """
            SELECT book, chapter, verse, text FROM verses
            WHERE translation = ? AND book_order = ? AND chapter = ?
            ORDER BY verse
            """
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(statement, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 2, Int32(bookOrder))
        sqlite3_bind_int(statement, 3, Int32(chapter))

        var results: [Verse] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let book = String(cString: sqlite3_column_text(statement, 0))
            let chapterNum = Int(sqlite3_column_int(statement, 1))
            let verseNum = Int(sqlite3_column_int(statement, 2))
            let text = String(cString: sqlite3_column_text(statement, 3))
            results.append(Verse(
                translation: translation.rawValue,
                book: book,
                bookOrder: bookOrder,
                chapter: chapterNum,
                verse: verseNum,
                text: text
            ))
        }
        return results
    }
}
