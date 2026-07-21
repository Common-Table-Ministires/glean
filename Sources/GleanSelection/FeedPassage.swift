import Foundation

/// One verse line used for focus/context rendering in the feed.
public struct FeedVerseLine: Hashable, Sendable {
    public let verse: Int
    public let text: String

    public init(verse: Int, text: String) {
        self.verse = verse
        self.text = text
    }
}

/// Curated ministry reflection — never mixed into the Scripture string itself.
/// Signed + confidence-tagged per docs/04-moderation-design.md.
public struct TheologyInsight: Hashable, Sendable {
    public enum Confidence: String, Hashable, Sendable {
        /// Broadly affirmed across Christian tradition.
        case widelyHeld = "Widely held"
        /// One faithful reading among several.
        case oneReading = "One reading among several"
        /// Honest personal / ministry reflection, not claimed as consensus.
        case personal = "Personal reflection"
    }

    public let body: String
    public let source: String
    public let confidence: Confidence

    public init(
        body: String,
        source: String = "Common Table Ministries",
        confidence: Confidence = .personal
    ) {
        self.body = body
        self.source = source
        self.confidence = confidence
    }
}

/// Display-only DTO so UI never imports scoring internals beyond what it needs to render.
/// Map from `ScriptureChunk` at the app boundary; Stories/Study may keep using ScriptureCore.Chunk.
///
/// Feed presentation is **focus-first**: one clear verse, surrounding context optional
/// (blurred until the reader pauses), theology lives with the context layer — never
/// over the clear focus text.
public struct FeedPassage: Identifiable, Hashable, Sendable {
    public let id: String
    /// Full range reference, e.g. "John 3:16-17".
    public let reference: String
    /// Focus-only reference, e.g. "John 3:16".
    public let focusReference: String
    public let focusText: String
    public let focusVerse: Int?
    public let contextBefore: [FeedVerseLine]
    public let contextAfter: [FeedVerseLine]
    /// Full plain text (share / search / fallbacks).
    public let text: String
    public let verseCount: Int
    public let wordCount: Int
    public let translation: String?
    public let theology: TheologyInsight?

    public var hasContext: Bool {
        !contextBefore.isEmpty || !contextAfter.isEmpty
    }

    public init(
        id: String,
        reference: String,
        focusReference: String,
        focusText: String,
        focusVerse: Int? = nil,
        contextBefore: [FeedVerseLine] = [],
        contextAfter: [FeedVerseLine] = [],
        text: String,
        verseCount: Int,
        wordCount: Int,
        translation: String? = nil,
        theology: TheologyInsight? = nil
    ) {
        self.id = id
        self.reference = reference
        self.focusReference = focusReference
        self.focusText = focusText
        self.focusVerse = focusVerse
        self.contextBefore = contextBefore
        self.contextAfter = contextAfter
        self.text = text
        self.verseCount = verseCount
        self.wordCount = wordCount
        self.translation = translation
        self.theology = theology
    }

    /// Legacy convenience: entire chunk is treated as the focus (no blur layers).
    public init(
        id: String,
        reference: String,
        text: String,
        verseCount: Int,
        wordCount: Int,
        translation: String? = nil,
        theology: TheologyInsight? = nil
    ) {
        self.id = id
        self.reference = reference
        self.focusReference = reference
        self.focusText = text
        self.focusVerse = nil
        self.contextBefore = []
        self.contextAfter = []
        self.text = text
        self.verseCount = verseCount
        self.wordCount = wordCount
        self.translation = translation
        self.theology = theology
    }

    public init(chunk: ScriptureChunk, theology: TheologyInsight? = nil) {
        // Without per-verse hydration, show the whole chunk as focus.
        // iOS prefers `FeedPassageBuilder` which splits against scripture.sqlite.
        self.id = chunk.id
        self.reference = chunk.reference
        self.focusReference = chunk.reference
        self.focusText = chunk.text
        self.focusVerse = chunk.startVerse
        self.contextBefore = []
        self.contextAfter = []
        self.text = chunk.text
        self.verseCount = chunk.verseCount
        self.wordCount = chunk.wordCount
        self.translation = chunk.translation
        self.theology = theology
    }
}
