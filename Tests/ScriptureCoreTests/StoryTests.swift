import XCTest
@testable import ScriptureCore

final class StoryTests: XCTestCase {
    private func realDatabasePath() -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let packageRoot = testFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return packageRoot
            .appendingPathComponent("Sources/ScripturePreview/Resources/scripture.sqlite")
            .path
    }

    func testAllCoreStoriesHaveUniqueIDs() {
        let ids = Story.core.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "duplicate story id found")
    }

    func testDavidAndGoliathCoversFullRangeInOrder() throws {
        let store = ScriptureStore(path: realDatabasePath())
        let story = try XCTUnwrap(Story.core.first { $0.id == "david-goliath" })
        let chunks = store.chunks(for: story, translation: .bsb)

        XCTAssertFalse(chunks.isEmpty)

        let allVerses = chunks.flatMap(\.verses).map(\.verse)
        XCTAssertEqual(allVerses, Array(1...51), "should cover I Samuel 17:1 through 17:51 with no gaps or overlaps")

        for chunk in chunks {
            XCTAssertEqual(chunk.book, "I Samuel")
            XCTAssertEqual(chunk.chapter, 17)
        }
    }

    func testNoahSpansMultipleChaptersInOrder() throws {
        let store = ScriptureStore(path: realDatabasePath())
        let story = try XCTUnwrap(Story.core.first { $0.id == "noah" })
        let chunks = store.chunks(for: story, translation: .kjv)

        XCTAssertFalse(chunks.isEmpty)
        let chapters = chunks.flatMap { chunk in Array(repeating: chunk.chapter, count: chunk.verses.count) }
        XCTAssertEqual(chapters, chapters.sorted(), "chapters must appear in non-decreasing order across the story")
        XCTAssertEqual(chunks.first?.chapter, 6)
        XCTAssertEqual(chunks.last?.chapter, 9)
    }
}
