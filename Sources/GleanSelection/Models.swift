import Foundation

// MARK: - Core models (selection package only — no UI, no SQLite)

/// A formation-sized Scripture unit (usually 3–15 verses), not a whole chapter dump.
public struct ScriptureChunk: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let reference: String
    public let text: String
    public let book: String
    public let displayBook: String?
    public let chapter: Int?
    public let startVerse: Int?
    public let endVerse: Int?
    public let genre: Genre
    public let testament: Testament?
    public let themes: [Theme]
    public let canonicalOrder: Int
    public let isPopular: Bool
    public let translation: String?

    public init(
        id: String,
        reference: String,
        text: String,
        book: String,
        displayBook: String? = nil,
        chapter: Int? = nil,
        startVerse: Int? = nil,
        endVerse: Int? = nil,
        genre: Genre,
        testament: Testament? = nil,
        themes: [Theme],
        canonicalOrder: Int,
        isPopular: Bool,
        translation: String? = nil
    ) {
        self.id = id
        self.reference = reference
        self.text = text
        self.book = book
        self.displayBook = displayBook
        self.chapter = chapter
        self.startVerse = startVerse
        self.endVerse = endVerse
        self.genre = genre
        self.testament = testament
        self.themes = themes
        self.canonicalOrder = canonicalOrder
        self.isPopular = isPopular
        self.translation = translation
    }

    enum CodingKeys: String, CodingKey {
        case id, reference, text, book, displayBook
        case chapter, startVerse, endVerse
        case genre, testament, themes, canonicalOrder, isPopular, translation
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        reference = try c.decode(String.self, forKey: .reference)
        text = try c.decode(String.self, forKey: .text)
        book = try c.decode(String.self, forKey: .book)
        displayBook = try c.decodeIfPresent(String.self, forKey: .displayBook)
        chapter = try c.decodeIfPresent(Int.self, forKey: .chapter)
        startVerse = try c.decodeIfPresent(Int.self, forKey: .startVerse)
        endVerse = try c.decodeIfPresent(Int.self, forKey: .endVerse)
        genre = try c.decode(Genre.self, forKey: .genre)
        testament = try c.decodeIfPresent(Testament.self, forKey: .testament)
        themes = try c.decode([Theme].self, forKey: .themes)
        canonicalOrder = try c.decode(Int.self, forKey: .canonicalOrder)
        isPopular = try c.decode(Bool.self, forKey: .isPopular)
        translation = try c.decodeIfPresent(String.self, forKey: .translation)
    }

    /// Approximate verse count from range when available.
    public var verseCount: Int {
        guard let start = startVerse, let end = endVerse else { return 0 }
        return max(end - start + 1, 0)
    }

    public var wordCount: Int {
        text.split(whereSeparator: \.isWhitespace).count
    }
}

public enum Testament: String, Codable, CaseIterable, Hashable, Sendable {
    case OT, NT
}

public enum Genre: String, Codable, CaseIterable, Hashable, Sendable {
    case torah, historical, wisdom, prophets
    case gospels, acts, epistles, apocalyptic
}

/// Fixed formation vocabulary — keep small so selection stays meaningful.
public enum Theme: String, Codable, CaseIterable, Hashable, Sendable {
    case hope, faith, love, wisdom, prayer
    case repentance, suffering, joy, justice
    case creation, kingdom, identity, peace
}

/// On-device history of what the person has already received.
public struct SeenChunk: Codable, Hashable, Identifiable, Sendable {
    public var id: String { chunkID }
    public var chunkID: String
    public var lastShown: Date
    public var timesShown: Int

    public init(chunkID: String, lastShown: Date = Date(), timesShown: Int = 1) {
        self.chunkID = chunkID
        self.lastShown = lastShown
        self.timesShown = timesShown
    }
}

// MARK: - Pack loading

public struct ChunkPack: Codable, Sendable {
    public let version: Int
    public let translation: String?
    public let count: Int?
    public let chunks: [ScriptureChunk]
}

public enum ChunkLoader {
    /// Load either a bare `[ScriptureChunk]` array or a `{ "chunks": [...] }` pack.
    public static func load(from url: URL) throws -> [ScriptureChunk] {
        let data = try Data(contentsOf: url)
        return try load(from: data)
    }

    public static func load(from data: Data) throws -> [ScriptureChunk] {
        let decoder = JSONDecoder()
        if let pack = try? decoder.decode(ChunkPack.self, from: data) {
            return pack.chunks
        }
        return try decoder.decode([ScriptureChunk].self, from: data)
    }

    /// Load the bundled formation pack shipped with this package.
    public static func loadBundledPack() throws -> [ScriptureChunk] {
        guard let url = Bundle.module.url(forResource: "chunks", withExtension: "json") else {
            throw ChunkLoaderError.missingResource("chunks.json")
        }
        return try load(from: url)
    }

    public static func loadBundleResource(
        name: String = "chunks",
        extension ext: String = "json",
        bundle: Bundle? = nil
    ) throws -> [ScriptureChunk] {
        let resolved = bundle ?? Bundle.module
        guard let url = resolved.url(forResource: name, withExtension: ext) else {
            throw ChunkLoaderError.missingResource("\(name).\(ext)")
        }
        return try load(from: url)
    }
}

public enum ChunkLoaderError: Error, LocalizedError, Sendable {
    case missingResource(String)

    public var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing chunk resource: \(name)"
        }
    }
}

// MARK: - Book catalog helpers

public enum BookCatalog {
    /// Formation genre for a ScripturePreview / sqlite book name.
    public static func genre(forBook book: String) -> Genre? {
        switch book {
        case "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy":
            return .torah
        case "Joshua", "Judges", "Ruth",
             "I Samuel", "II Samuel", "I Kings", "II Kings",
             "I Chronicles", "II Chronicles", "Ezra", "Nehemiah", "Esther":
            return .historical
        case "Job", "Psalms", "Proverbs", "Ecclesiastes", "Song of Solomon":
            return .wisdom
        case "Isaiah", "Jeremiah", "Lamentations", "Ezekiel", "Daniel",
             "Hosea", "Joel", "Amos", "Obadiah", "Jonah", "Micah",
             "Nahum", "Habakkuk", "Zephaniah", "Haggai", "Zechariah", "Malachi":
            return .prophets
        case "Matthew", "Mark", "Luke", "John":
            return .gospels
        case "Acts":
            return .acts
        case "Romans", "I Corinthians", "II Corinthians", "Galatians", "Ephesians",
             "Philippians", "Colossians", "I Thessalonians", "II Thessalonians",
             "I Timothy", "II Timothy", "Titus", "Philemon", "Hebrews", "James",
             "I Peter", "II Peter", "I John", "II John", "III John", "Jude":
            return .epistles
        case "Revelation of John", "Revelation":
            return .apocalyptic
        default:
            return nil
        }
    }

    public static func testament(forBook book: String) -> Testament? {
        guard let genre = genre(forBook: book) else { return nil }
        switch genre {
        case .torah, .historical, .wisdom, .prophets: return .OT
        case .gospels, .acts, .epistles, .apocalyptic: return .NT
        }
    }
}
