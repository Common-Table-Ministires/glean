import Foundation

public struct Chunk: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let translation: String
    public let book: String
    public let chapter: Int
    public let verseRange: ClosedRange<Int>
    public let verses: [Verse]

    public init(translation: String, book: String, chapter: Int, verseRange: ClosedRange<Int>, verses: [Verse]) {
        self.translation = translation
        self.book = book
        self.chapter = chapter
        self.verseRange = verseRange
        self.verses = verses
    }

    public var reference: String {
        if verseRange.lowerBound == verseRange.upperBound {
            return "\(book) \(chapter):\(verseRange.lowerBound)"
        }
        return "\(book) \(chapter):\(verseRange.lowerBound)-\(verseRange.upperBound)"
    }

    public var text: String {
        verses.map(\.text).joined(separator: " ")
    }
}
