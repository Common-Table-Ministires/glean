import Foundation

/// Thin, UI-free session controller: load pack → select → record → persist.
/// Reader apps should own one of these for Feed; they must not reimplement scoring.
public final class GleanFeedSession: @unchecked Sendable {
    public private(set) var algorithm: GleanAlgorithm
    public private(set) var history: [SeenChunk]
    public let historyStore: SeenHistoryStore
    public var preferredThemes: [Theme]
    public var boostDiversity: Bool

    public var isReady: Bool { !algorithm.allChunks.isEmpty }
    public var packCount: Int { algorithm.allChunks.count }

    /// Build from an explicit chunk list (tests / custom packs).
    public init(
        chunks: [ScriptureChunk],
        config: GleanConfig = .default,
        historyStore: SeenHistoryStore = SeenHistoryStore(),
        preferredThemes: [Theme] = [],
        boostDiversity: Bool = true
    ) {
        self.algorithm = GleanAlgorithm(allChunks: chunks, config: config)
        self.historyStore = historyStore
        self.history = historyStore.load()
        self.preferredThemes = preferredThemes
        self.boostDiversity = boostDiversity
    }

    /// Load the bundled formation pack shipped with GleanSelection.
    /// Defaults to `.continuousFeed` so a 64-item pack is not locked out for 90 days
    /// after one reading pass (that forced the app into SQLite “offline random”).
    public convenience init(
        config: GleanConfig = .continuousFeed,
        historyStore: SeenHistoryStore = SeenHistoryStore(),
        preferredThemes: [Theme] = [],
        boostDiversity: Bool = true
    ) throws {
        let chunks = try ChunkLoader.loadBundledPack()
        self.init(
            chunks: chunks,
            config: config,
            historyStore: historyStore,
            preferredThemes: preferredThemes,
            boostDiversity: boostDiversity
        )
    }

    /// Select the next formation chunk and persist history. Returns nil if none eligible.
    public func next(now: Date = Date()) -> ScriptureChunk? {
        if let pick = algorithm.selectDailyChunk(
            history: history,
            preferredThemes: preferredThemes,
            boostDiversity: boostDiversity,
            now: now
        ) {
            algorithm.recordShown(chunkID: pick.id, history: &history, at: now)
            historyStore.save(history)
            return pick
        }

        // Safety net: if hard cooldowns still empty the set, re-rank with continuous rules.
        var relaxed = algorithm
        relaxed.config = .continuousFeed
        guard let pick = relaxed.selectDailyChunk(
            history: history,
            preferredThemes: preferredThemes,
            boostDiversity: boostDiversity,
            now: now
        ) else {
            return nil
        }
        algorithm.recordShown(chunkID: pick.id, history: &history, at: now)
        historyStore.save(history)
        return pick
    }

    public func eligibleCount(now: Date = Date()) -> Int {
        algorithm.eligibleCount(history: history, now: now)
    }

    public func rankCandidates(now: Date = Date()) -> [(chunk: ScriptureChunk, score: Double)] {
        algorithm.rankCandidates(
            history: history,
            preferredThemes: preferredThemes,
            boostDiversity: boostDiversity,
            now: now
        )
    }
}
