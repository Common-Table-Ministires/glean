import XCTest
@testable import ScriptureCore

final class ChunkerTests: XCTestCase {
    private func verse(_ chapter: Int, _ verse: Int, words: Int) -> Verse {
        let text = Array(repeating: "word", count: words).joined(separator: " ")
        return Verse(translation: "TEST", book: "Test", bookOrder: 1, chapter: chapter, verse: verse, text: text)
    }

    func testGroupsUntilMinimumWordCount() {
        let verses = [
            verse(1, 1, words: 15),
            verse(1, 2, words: 15),
            verse(1, 3, words: 15),
            verse(1, 4, words: 15),
        ]
        let chunks = Chunker.chunk(verses: verses, minWords: 40)
        XCTAssertEqual(chunks.count, 2, "45 words should close the first chunk after verse 3, leaving verse 4 alone")
        XCTAssertEqual(chunks[0].verseRange, 1...3)
        XCTAssertEqual(chunks[1].verseRange, 4...4)
    }

    func testNeverMergesAcrossChapterBoundary() {
        let verses = [
            verse(1, 20, words: 5),
            verse(2, 1, words: 5),
        ]
        let chunks = Chunker.chunk(verses: verses, minWords: 40)
        XCTAssertEqual(chunks.count, 2, "a chapter boundary must always start a new chunk even under the word minimum")
        XCTAssertEqual(chunks[0].chapter, 1)
        XCTAssertEqual(chunks[1].chapter, 2)
    }

    func testSingleLongVerseFormsItsOwnChunk() {
        let verses = [verse(1, 1, words: 90)]
        let chunks = Chunker.chunk(verses: verses, minWords: 40)
        XCTAssertEqual(chunks.count, 1)
        XCTAssertEqual(chunks[0].verseRange, 1...1)
    }

    func testEmptyInputProducesNoChunks() {
        XCTAssertEqual(Chunker.chunk(verses: [], minWords: 40).count, 0)
    }
}
