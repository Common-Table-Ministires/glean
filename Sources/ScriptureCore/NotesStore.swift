import Foundation

/// Per-verse personal notes, persisted locally only (per 01-principles.md: no account
/// required to read, and this isn't shared with anyone). Backed by UserDefaults for
/// now since note volume per person is small; worth moving to the SQLite database
/// if that assumption stops holding.
public final class NotesStore: ObservableObject {
    private static let defaultsKey = "scriptureapp.notes.v1"

    @Published public private(set) var notes: [String: String]

    public init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            notes = decoded
        } else {
            notes = [:]
        }
    }

    public func note(bookOrder: Int, chapter: Int, verse: Int) -> String {
        notes[Self.key(bookOrder, chapter, verse)] ?? ""
    }

    public func setNote(_ text: String, bookOrder: Int, chapter: Int, verse: Int) {
        let key = Self.key(bookOrder, chapter, verse)
        if text.isEmpty {
            notes.removeValue(forKey: key)
        } else {
            notes[key] = text
        }
        persist()
    }

    private static func key(_ bookOrder: Int, _ chapter: Int, _ verse: Int) -> String {
        "\(bookOrder):\(chapter):\(verse)"
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
