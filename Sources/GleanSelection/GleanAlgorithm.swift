import Foundation

// MARK: - Configuration

public struct GleanConfig: Hashable, Sendable {
    /// Cooldown for ordinary chunks before they may reappear.
    public var normalCooldownDays: Int
    /// Longer cooldown for widely known / over-quoted passages.
    public var popularCooldownDays: Int
    /// Prefer chunks whose genre hasn't appeared in this many recent shows.
    public var recentGenreWindow: Int
    /// Soft theme cooldown: prefer themes not seen in this many recent shows.
    public var recentThemeWindow: Int
    /// When true, slightly prefer the underrepresented testament in recent history.
    public var balanceTestaments: Bool
    /// Among top scores, pick randomly from this many leaders (1 = pure max).
    public var topK: Int
    /// Optional RNG seed for tests; nil uses system randomness.
    public var randomSeed: UInt64?

    public init(
        normalCooldownDays: Int = 90,
        popularCooldownDays: Int = 180,
        recentGenreWindow: Int = 15,
        recentThemeWindow: Int = 10,
        balanceTestaments: Bool = true,
        topK: Int = 3,
        randomSeed: UInt64? = nil
    ) {
        self.normalCooldownDays = normalCooldownDays
        self.popularCooldownDays = popularCooldownDays
        self.recentGenreWindow = recentGenreWindow
        self.recentThemeWindow = recentThemeWindow
        self.balanceTestaments = balanceTestaments
        self.topK = topK
        self.randomSeed = randomSeed
    }

    public static let `default` = GleanConfig()

    /// Continuous mobile flip feed: no multi-month hard lockout.
    /// Diversity still comes from scoring (recency, genre, theme), not 90-day cooldowns.
    /// Using the long cooldowns empty the 64-chunk pack after one pass → "offline random".
    public static let continuousFeed = GleanConfig(
        normalCooldownDays: 0,
        popularCooldownDays: 0,
        recentGenreWindow: 10,
        recentThemeWindow: 8,
        balanceTestaments: true,
        topK: 5
    )
}

// MARK: - Algorithm

public struct GleanAlgorithm: Sendable {

    public let allChunks: [ScriptureChunk]
    public var config: GleanConfig

    private let chunkByID: [String: ScriptureChunk]
    /// Mutable LCG state when `config.randomSeed` is set (tests).
    private var rngState: UInt64

    public init(allChunks: [ScriptureChunk], config: GleanConfig = .default) {
        self.allChunks = allChunks
        self.config = config
        // uniquingKeysWithValues: never trap if a pack ships a duplicate id
        self.chunkByID = Dictionary(allChunks.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.rngState = config.randomSeed ?? 0
    }

    // MARK: Selection

    /// Pick one formation chunk for today / this session.
    /// Hard constraints (cooldowns) first; soft scoring second; top-K random third.
    public mutating func selectDailyChunk(
        history: [SeenChunk],
        preferredThemes: [Theme] = [],
        boostDiversity: Bool = true,
        now: Date = Date()
    ) -> ScriptureChunk? {
        let scored = rankCandidates(
            history: history,
            preferredThemes: preferredThemes,
            boostDiversity: boostDiversity,
            now: now
        )
        guard !scored.isEmpty else { return nil }

        let k = max(1, config.topK)
        let leaders = Array(scored.prefix(k))
        return weightedPick(from: leaders)
    }

    /// Full ranked list for debugging / UI “why this?” views.
    public func rankCandidates(
        history: [SeenChunk],
        preferredThemes: [Theme] = [],
        boostDiversity: Bool = true,
        now: Date = Date()
    ) -> [(chunk: ScriptureChunk, score: Double)] {
        let calendar = Calendar.current
        // Prefer the latest entry if history ever contains duplicates.
        let seenMap = Dictionary(history.map { ($0.chunkID, $0) }, uniquingKeysWith: { _, last in last })

        let candidates = allChunks.filter { chunk in
            isEligible(chunk, seen: seenMap[chunk.id], now: now, calendar: calendar)
        }
        guard !candidates.isEmpty else { return [] }

        let recentGenres = recentGenres(from: history, window: config.recentGenreWindow)
        let recentThemes = recentThemes(from: history, window: config.recentThemeWindow)
        let recentTestaments = recentTestaments(from: history, window: config.recentGenreWindow)

        let scored = candidates.map { chunk -> (chunk: ScriptureChunk, score: Double) in
            var score: Double = 0

            if !preferredThemes.isEmpty {
                let matches = Set(chunk.themes).intersection(preferredThemes).count
                score += Double(matches) * 3.0
            }

            if let seen = seenMap[chunk.id] {
                let days = daysBetween(seen.lastShown, now, calendar: calendar)
                score += min(Double(days) / 20.0, 6.0)
                score -= min(Double(seen.timesShown - 1) * 0.25, 2.0)
            } else {
                score += 4.0
            }

            if boostDiversity {
                if !recentGenres.contains(chunk.genre) {
                    score += 2.0
                }
                let novelThemes = Set(chunk.themes).subtracting(recentThemes)
                score += Double(novelThemes.count) * 0.75

                if config.balanceTestaments, let t = chunk.testament ?? BookCatalog.testament(forBook: chunk.book) {
                    let ot = recentTestaments.filter { $0 == .OT }.count
                    let nt = recentTestaments.filter { $0 == .NT }.count
                    if ot > nt + 1, t == .NT { score += 1.0 }
                    if nt > ot + 1, t == .OT { score += 1.0 }
                }
            }

            if chunk.isPopular {
                score -= 0.35
            }

            return (chunk, score)
        }

        return scored.sorted { lhs, rhs in
            if lhs.score != rhs.score { return lhs.score > rhs.score }
            let lSeen = seenMap[lhs.chunk.id]?.timesShown ?? 0
            let rSeen = seenMap[rhs.chunk.id]?.timesShown ?? 0
            if lSeen != rSeen { return lSeen < rSeen }
            return lhs.chunk.canonicalOrder < rhs.chunk.canonicalOrder
        }
    }

    // MARK: History

    public func recordShown(chunkID: String, history: inout [SeenChunk], at date: Date = Date()) {
        if let index = history.firstIndex(where: { $0.chunkID == chunkID }) {
            history[index].lastShown = date
            history[index].timesShown += 1
        } else {
            history.append(SeenChunk(chunkID: chunkID, lastShown: date, timesShown: 1))
        }
    }

    /// How many chunks are still eligible under current cooldowns.
    public func eligibleCount(history: [SeenChunk], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        let seenMap = Dictionary(history.map { ($0.chunkID, $0) }, uniquingKeysWith: { _, last in last })
        return allChunks.filter { isEligible($0, seen: seenMap[$0.id], now: now, calendar: calendar) }.count
    }

    /// Theme coverage of the loaded corpus (for diagnostics).
    public func themeCoverage() -> [Theme: Int] {
        var counts = Dictionary(uniqueKeysWithValues: Theme.allCases.map { ($0, 0) })
        for chunk in allChunks {
            for theme in chunk.themes {
                counts[theme, default: 0] += 1
            }
        }
        return counts
    }

    // MARK: Internals

    private func isEligible(
        _ chunk: ScriptureChunk,
        seen: SeenChunk?,
        now: Date,
        calendar: Calendar
    ) -> Bool {
        guard let seen else { return true }
        let daysSince = daysBetween(seen.lastShown, now, calendar: calendar)
        let required = chunk.isPopular ? config.popularCooldownDays : config.normalCooldownDays
        return daysSince >= required
    }

    private func daysBetween(_ from: Date, _ to: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    private func recentGenres(from history: [SeenChunk], window: Int) -> Set<Genre> {
        Set(history.suffix(window).compactMap { chunkByID[$0.chunkID]?.genre })
    }

    private func recentThemes(from history: [SeenChunk], window: Int) -> Set<Theme> {
        var themes = Set<Theme>()
        for seen in history.suffix(window) {
            if let chunk = chunkByID[seen.chunkID] {
                themes.formUnion(chunk.themes)
            }
        }
        return themes
    }

    private func recentTestaments(from history: [SeenChunk], window: Int) -> [Testament] {
        history.suffix(window).compactMap { seen in
            guard let chunk = chunkByID[seen.chunkID] else { return nil }
            return chunk.testament ?? BookCatalog.testament(forBook: chunk.book)
        }
    }

    private mutating func weightedPick(from leaders: [(chunk: ScriptureChunk, score: Double)]) -> ScriptureChunk? {
        guard let first = leaders.first else { return nil }
        if leaders.count == 1 || config.topK <= 1 { return first.chunk }

        let minScore = leaders.map(\.score).min() ?? 0
        let weights = leaders.map { max($0.score - minScore + 1.0, 0.1) }
        let total = weights.reduce(0, +)
        var r = randomUnit() * total
        for (i, w) in weights.enumerated() {
            r -= w
            if r <= 0 { return leaders[i].chunk }
        }
        return leaders.last?.chunk
    }

    private mutating func randomUnit() -> Double {
        if config.randomSeed != nil {
            // Numerical Recipes LCG
            rngState = rngState &* 1_664_525 &+ 1_013_904_223
            return Double(rngState % 10_000) / 10_000.0
        }
        return Double.random(in: 0..<1)
    }
}
