import XCTest
@testable import GleanSelection

final class GleanSelectionTests: XCTestCase {

    func testBundledPackLoads64Chunks() throws {
        let chunks = try ChunkLoader.loadBundledPack()
        XCTAssertEqual(chunks.count, 64)
        XCTAssertFalse(chunks[0].text.isEmpty)
        XCTAssertFalse(chunks[0].themes.isEmpty)
    }

    func testCooldownExcludesRecentlyShown() throws {
        let chunks = try ChunkLoader.loadBundledPack()
        var config = GleanConfig.default
        config.topK = 1
        config.randomSeed = 42
        var algo = GleanAlgorithm(allChunks: chunks, config: config)

        let first = try XCTUnwrap(algo.selectDailyChunk(history: [], preferredThemes: [.hope]))
        var history: [SeenChunk] = []
        algo.recordShown(chunkID: first.id, history: &history)

        // Immediately after show: first id must not reappear
        let second = try XCTUnwrap(algo.selectDailyChunk(history: history, preferredThemes: [.hope]))
        XCTAssertNotEqual(first.id, second.id)

        // Within cooldown window, eligible count drops by at least 1
        XCTAssertLessThan(algo.eligibleCount(history: history), chunks.count)
    }

    func testPopularUsesLongerCooldown() throws {
        let popular = ScriptureChunk(
            id: "POP.1",
            reference: "Test 1:1",
            text: "Popular text",
            book: "Psalms",
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            genre: .wisdom,
            testament: .OT,
            themes: [.hope],
            canonicalOrder: 1,
            isPopular: true
        )
        let normal = ScriptureChunk(
            id: "NOR.1",
            reference: "Test 2:1",
            text: "Normal text",
            book: "James",
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            genre: .epistles,
            testament: .NT,
            themes: [.faith],
            canonicalOrder: 2,
            isPopular: false
        )
        let config = GleanConfig(
            normalCooldownDays: 90,
            popularCooldownDays: 180,
            topK: 1,
            randomSeed: 1
        )
        var algo = GleanAlgorithm(allChunks: [popular, normal], config: config)
        let now = Date()
        let history = [
            SeenChunk(chunkID: popular.id, lastShown: Calendar.current.date(byAdding: .day, value: -100, to: now)!, timesShown: 1),
            SeenChunk(chunkID: normal.id, lastShown: Calendar.current.date(byAdding: .day, value: -100, to: now)!, timesShown: 1),
        ]
        // Popular still cooling (need 180); normal eligible at 100 >= 90
        XCTAssertEqual(algo.eligibleCount(history: history, now: now), 1)
        let pick = try XCTUnwrap(algo.selectDailyChunk(history: history, preferredThemes: [], now: now))
        XCTAssertEqual(pick.id, normal.id)
    }

    func testPreferredThemesBoostRanking() throws {
        let hope = ScriptureChunk(
            id: "H",
            reference: "Hope 1:1",
            text: "hope",
            book: "Romans",
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            genre: .epistles,
            testament: .NT,
            themes: [.hope],
            canonicalOrder: 10,
            isPopular: false
        )
        let justice = ScriptureChunk(
            id: "J",
            reference: "Justice 1:1",
            text: "justice",
            book: "Amos",
            chapter: 1,
            startVerse: 1,
            endVerse: 1,
            genre: .prophets,
            testament: .OT,
            themes: [.justice],
            canonicalOrder: 20,
            isPopular: false
        )
        let config = GleanConfig(topK: 1, randomSeed: 7)
        var algo = GleanAlgorithm(allChunks: [hope, justice], config: config)
        let ranked = algo.rankCandidates(history: [], preferredThemes: [.justice])
        XCTAssertEqual(ranked.first?.chunk.id, "J")
        let pick = try XCTUnwrap(algo.selectDailyChunk(history: [], preferredThemes: [.justice]))
        XCTAssertEqual(pick.id, "J")
    }

    func testFeedSessionPersistsHistory() throws {
        let defaults = UserDefaults(suiteName: "GleanSelectionTests.\(UUID().uuidString)")!
        defer { defaults.removePersistentDomain(forName: defaults.dictionaryRepresentation().keys.first ?? "") }

        let store = SeenHistoryStore(defaults: defaults, key: "test.seen")
        let chunks = try ChunkLoader.loadBundledPack()
        let session = GleanFeedSession(
            chunks: chunks,
            config: GleanConfig(topK: 1, randomSeed: 99),
            historyStore: store
        )
        let a = try XCTUnwrap(session.next())
        XCTAssertEqual(store.load().count, 1)
        XCTAssertEqual(store.load().first?.chunkID, a.id)

        let session2 = GleanFeedSession(
            chunks: chunks,
            config: GleanConfig(topK: 1, randomSeed: 99),
            historyStore: store
        )
        XCTAssertEqual(session2.history.count, 1)
        let b = try XCTUnwrap(session2.next())
        XCTAssertNotEqual(a.id, b.id)
    }

    func testFeedPassageMapsFromChunk() throws {
        let chunks = try ChunkLoader.loadBundledPack()
        let passage = FeedPassage(chunk: chunks[0])
        XCTAssertEqual(passage.id, chunks[0].id)
        XCTAssertEqual(passage.reference, chunks[0].reference)
        XCTAssertEqual(passage.text, chunks[0].text)
        XCTAssertGreaterThan(passage.wordCount, 0)
    }
}
