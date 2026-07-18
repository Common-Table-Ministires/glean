import XCTest
@testable import ScriptureCore

final class ScriptureStoreTests: XCTestCase {
    private func realDatabasePath() -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let packageRoot = testFile
            .deletingLastPathComponent() // ScriptureStoreTests.swift -> ScriptureCoreTests/
            .deletingLastPathComponent() // ScriptureCoreTests/ -> Tests/
            .deletingLastPathComponent() // Tests/ -> package root
        return packageRoot
            .appendingPathComponent("Sources/ScripturePreview/Resources/scripture.sqlite")
            .path
    }

    func testRandomChunkReturnsRealMultiVerseText() throws {
        let store = ScriptureStore(path: realDatabasePath())
        for translation in BibleTranslation.allCases {
            guard let chunk = store.randomChunk(translation: translation) else {
                XCTFail("expected a chunk for \(translation.rawValue)")
                continue
            }
            XCTAssertFalse(chunk.verses.isEmpty)
            XCTAssertFalse(chunk.text.isEmpty)
            XCTAssertEqual(chunk.translation, translation.rawValue)
            XCTAssertTrue(chunk.reference.contains(String(chunk.chapter)))
        }
    }

    func testManyDrawsProduceVariedChunkSizes() throws {
        let store = ScriptureStore(path: realDatabasePath())
        var verseCounts: Set<Int> = []
        for _ in 0..<25 {
            if let chunk = store.randomChunk(translation: .bsb) {
                verseCounts.insert(chunk.verses.count)
            }
        }
        XCTAssertGreaterThan(verseCounts.count, 1, "real Scripture text should not all chunk to the exact same verse count")
    }
}
