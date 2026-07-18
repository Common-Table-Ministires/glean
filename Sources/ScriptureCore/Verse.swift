import Foundation

public struct Verse: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let translation: String
    public let book: String
    public let bookOrder: Int
    public let chapter: Int
    public let verse: Int
    public let text: String

    public init(translation: String, book: String, bookOrder: Int, chapter: Int, verse: Int, text: String) {
        self.translation = translation
        self.book = book
        self.bookOrder = bookOrder
        self.chapter = chapter
        self.verse = verse
        self.text = text
    }
}
