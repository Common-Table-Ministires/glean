import XCTest
@testable import GleanCommentary

final class GleanCommentaryTests: XCTestCase {
    func testBundledPackLoads() throws {
        let store = try CommentaryStore()
        XCTAssertGreaterThanOrEqual(store.sourceCount, 3)
        XCTAssertGreaterThanOrEqual(store.noteCount, 10)
    }

    func testLookupByPackId() throws {
        let store = try CommentaryStore()
        let hits = store.excerpts(packId: "JHN.3.16-17")
        XCTAssertFalse(hits.isEmpty)
        XCTAssertTrue(hits.contains { $0.source.author.contains("Henry") })
    }

    func testLookupByBookChapterVerse() throws {
        let store = try CommentaryStore()
        let hits = store.excerpts(book: "John", chapter: 3, verse: 16)
        XCTAssertFalse(hits.isEmpty)
        for hit in hits {
            XCTAssertFalse(hit.note.text.isEmpty)
            XCTAssertEqual(hit.source.license, "public-domain")
        }
    }

    func testUnknownRefReturnsEmpty() throws {
        let store = try CommentaryStore()
        let hits = store.excerpts(packId: "ZZZ.99.99", book: "Obadiah", chapter: 1, verse: 99)
        XCTAssertTrue(hits.isEmpty)
    }

    func testSharedStoreNonEmpty() {
        // shared falls back to empty only if resources missing
        XCTAssertFalse(CommentaryStore.shared.isEmpty)
    }
}
