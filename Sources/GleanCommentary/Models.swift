import Foundation

// MARK: - Sources

/// A commentator or work allowed in the offline pack.
public struct CommentarySource: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let author: String
    public let work: String
    /// e.g. Protestant, Patristic, Reformed
    public let tradition: String
    public let era: String
    /// `public-domain`, `CC0`, `CC-BY-4.0`, etc.
    public let license: String
    public let notes: String?

    public init(
        id: String,
        author: String,
        work: String,
        tradition: String,
        era: String,
        license: String,
        notes: String? = nil
    ) {
        self.id = id
        self.author = author
        self.work = work
        self.tradition = tradition
        self.era = era
        self.license = license
        self.notes = notes
    }

    /// One-line attribution for UI / share sheets.
    public var attribution: String {
        "\(author), \(work)"
    }
}

// MARK: - Notes

public enum CommentaryConfidence: String, Codable, Hashable, Sendable {
    case widelyHeld
    case oneReading
    case personal

    public var displayName: String {
        switch self {
        case .widelyHeld: return "Widely held"
        case .oneReading: return "One reading among several"
        case .personal: return "Personal reflection"
        }
    }
}

/// A short, signed excerpt keyed to Scripture.
public struct CommentaryNote: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let sourceId: String
    /// Formation pack id when known, e.g. `JHN.3.16-17`.
    public let packId: String?
    /// Human reference for the focus, e.g. `John 3:16`.
    public let focusReference: String
    public let book: String
    public let chapter: Int
    public let verse: Int
    /// Optional end of a short range (inclusive).
    public let endVerse: Int?
    public let text: String
    public let confidence: CommentaryConfidence

    public init(
        id: String,
        sourceId: String,
        packId: String? = nil,
        focusReference: String,
        book: String,
        chapter: Int,
        verse: Int,
        endVerse: Int? = nil,
        text: String,
        confidence: CommentaryConfidence = .oneReading
    ) {
        self.id = id
        self.sourceId = sourceId
        self.packId = packId
        self.focusReference = focusReference
        self.book = book
        self.chapter = chapter
        self.verse = verse
        self.endVerse = endVerse
        self.text = text
        self.confidence = confidence
    }

    public func covers(verse v: Int) -> Bool {
        let end = endVerse ?? verse
        return v >= verse && v <= end
    }
}

// MARK: - Pack file shapes

struct CommentarySourcesFile: Codable, Sendable {
    let version: Int
    let sources: [CommentarySource]
}

struct CommentaryNotesFile: Codable, Sendable {
    let version: Int
    let notes: [CommentaryNote]
}

// MARK: - Resolved display row

/// Note + joined source metadata for the UI.
public struct CommentaryExcerpt: Identifiable, Hashable, Sendable {
    public var id: String { note.id }
    public let note: CommentaryNote
    public let source: CommentarySource

    public init(note: CommentaryNote, source: CommentarySource) {
        self.note = note
        self.source = source
    }

    public var authorLine: String { source.attribution }
    public var traditionLine: String {
        "\(source.tradition) · \(source.era) · \(source.license)"
    }
}
