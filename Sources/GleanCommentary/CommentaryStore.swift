import Foundation

/// Loads the bundled open-commentary pack and answers lookups.
/// Pack is immutable after load; safe for main-thread UI.
public final class CommentaryStore: @unchecked Sendable {
    public static let shared: CommentaryStore = {
        (try? CommentaryStore()) ?? CommentaryStore(sources: [], notes: [])
    }()

    public let sources: [CommentarySource]
    public let notes: [CommentaryNote]

    private let sourceByID: [String: CommentarySource]
    private let notesByPackID: [String: [CommentaryNote]]
    private let notesByBookChapter: [String: [CommentaryNote]]

    public var isEmpty: Bool { notes.isEmpty }
    public var sourceCount: Int { sources.count }
    public var noteCount: Int { notes.count }

    public init(sources: [CommentarySource], notes: [CommentaryNote]) {
        self.sources = sources
        self.notes = notes
        self.sourceByID = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })

        var byPack: [String: [CommentaryNote]] = [:]
        var byBC: [String: [CommentaryNote]] = [:]
        for n in notes {
            if let pid = n.packId {
                byPack[pid, default: []].append(n)
            }
            let key = Self.bookChapterKey(book: n.book, chapter: n.chapter)
            byBC[key, default: []].append(n)
        }
        self.notesByPackID = byPack
        self.notesByBookChapter = byBC
    }

    /// Load bundled `sources.json` + `notes.json`.
    public convenience init() throws {
        let sourcesURL = try Self.resourceURL(name: "sources", ext: "json")
        let notesURL = try Self.resourceURL(name: "notes", ext: "json")
        let decoder = JSONDecoder()
        let sourcesFile = try decoder.decode(CommentarySourcesFile.self, from: Data(contentsOf: sourcesURL))
        let notesFile = try decoder.decode(CommentaryNotesFile.self, from: Data(contentsOf: notesURL))
        self.init(sources: sourcesFile.sources, notes: notesFile.notes)
    }

    // MARK: - Lookup

    /// Prefer pack id, then book-chapter-verse, then focus reference string.
    public func excerpts(
        packId: String? = nil,
        focusReference: String? = nil,
        book: String? = nil,
        chapter: Int? = nil,
        verse: Int? = nil,
        limit: Int = 4
    ) -> [CommentaryExcerpt] {
        var matched: [CommentaryNote] = []

        func appendUnique(_ list: [CommentaryNote]) {
            for n in list where !matched.contains(where: { $0.id == n.id }) {
                matched.append(n)
            }
        }

        if let packId {
            appendUnique(notesByPackID[packId] ?? [])
            // JHN.3.16-17 → also try JHN.3.16
            if let dash = packId.firstIndex(of: "-") {
                let stem = String(packId[..<dash])
                appendUnique(notesByPackID[stem] ?? [])
            }
            // Notes whose packId is a prefix of the formation id
            for n in notes {
                if let pid = n.packId, packId.hasPrefix(pid) || pid.hasPrefix(String(packId.prefix(while: { $0 != "-" }))) {
                    appendUnique([n])
                }
            }
        }

        if let book, let chapter {
            let key = Self.bookChapterKey(book: book, chapter: chapter)
            let chapterNotes = notesByBookChapter[key] ?? []
            if let verse {
                appendUnique(chapterNotes.filter { $0.covers(verse: verse) })
            } else {
                appendUnique(chapterNotes)
            }
        }

        if let focusReference {
            let norm = Self.normalizeRef(focusReference)
            appendUnique(notes.filter {
                let nref = Self.normalizeRef($0.focusReference)
                return nref == norm || norm.contains(nref) || nref.contains(norm)
            })
        }

        return matched.prefix(limit).compactMap { note in
            guard let source = sourceByID[note.sourceId] else { return nil }
            return CommentaryExcerpt(note: note, source: source)
        }
    }

    public func source(id: String) -> CommentarySource? {
        sourceByID[id]
    }

    // MARK: - Helpers

    private static func bookChapterKey(book: String, chapter: Int) -> String {
        "\(normalizeBook(book))|\(chapter)"
    }

    private static func normalizeBook(_ book: String) -> String {
        var b = book.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: " ", with: "")
        // Common Bible name aliases used across packs / sqlite
        let aliases: [String: String] = [
            "psalm": "psalms",
            "songofsolomon": "songofsongs",
            "canticles": "songofsongs",
            "revelationofjohn": "revelation",
            "apocalypse": "revelation",
            "isamuel": "1samuel",
            "iisamuel": "2samuel",
            "ikings": "1kings",
            "iikings": "2kings",
            "ichronicles": "1chronicles",
            "iichronicles": "2chronicles",
            "icorinthians": "1corinthians",
            "iicorinthians": "2corinthians",
            "ithessalonians": "1thessalonians",
            "iithessalonians": "2thessalonians",
            "itimothy": "1timothy",
            "iitimothy": "2timothy",
            "ipeter": "1peter",
            "iipeter": "2peter",
            "ijohn": "1john",
            "iijohn": "2john",
            "iiijohn": "3john",
        ]
        if b.hasPrefix("1"), b.count > 1, !b.hasPrefix("1s"), !b.hasPrefix("1c"), !b.hasPrefix("1t"), !b.hasPrefix("1p"), !b.hasPrefix("1j") {
            // already arabic numeral books like "1corinthians"
        }
        // "i corinthians" already stripped spaces → "icorinthians"
        if let mapped = aliases[b] { b = mapped }
        return b
    }

    private static func normalizeRef(_ ref: String) -> String {
        ref.lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
    }

    private static func resourceURL(name: String, ext: String) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
            throw CommentaryStoreError.missingResource("\(name).\(ext)")
        }
        return url
    }
}

public enum CommentaryStoreError: Error, LocalizedError, Sendable {
    case missingResource(String)

    public var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing commentary resource: \(name)"
        }
    }
}
