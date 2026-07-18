import Foundation

/// A curated core Bible story: a named, bounded reference range meant to be read
/// in order, start to finish, as a browsable alternative to the random feed.
///
/// This list is editorial content, not derived from the text itself; there is no
/// single agreed-upon canon of "the core stories." What's here is a first-pass,
/// widely-recognizable draft (the kind of list a children's story Bible or a
/// "stories everyone should know" table of contents would have), meant to be
/// reviewed and edited, not treated as settled.
///
/// All entries below are single-book ranges. `ScriptureStore.chunks(for:translation:)`
/// relies on that; a story spanning two books would need that query rewritten.
public struct Story: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let testament: String
    public let bookOrder: Int
    public let book: String
    public let startChapter: Int
    public let startVerse: Int
    public let endChapter: Int
    public let endVerse: Int

    public init(id: String, title: String, testament: String, bookOrder: Int, book: String, startChapter: Int, startVerse: Int, endChapter: Int, endVerse: Int) {
        self.id = id
        self.title = title
        self.testament = testament
        self.bookOrder = bookOrder
        self.book = book
        self.startChapter = startChapter
        self.startVerse = startVerse
        self.endChapter = endChapter
        self.endVerse = endVerse
    }

    public static let core: [Story] = [
        Story(id: "creation", title: "Creation", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 1, startVerse: 1, endChapter: 2, endVerse: 3),
        Story(id: "fall", title: "Adam, Eve, and the Fall", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 2, startVerse: 4, endChapter: 3, endVerse: 24),
        Story(id: "cain-abel", title: "Cain and Abel", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 4, startVerse: 1, endChapter: 4, endVerse: 16),
        Story(id: "noah", title: "Noah and the Flood", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 6, startVerse: 9, endChapter: 9, endVerse: 17),
        Story(id: "babel", title: "The Tower of Babel", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 11, startVerse: 1, endChapter: 11, endVerse: 9),
        Story(id: "abrahams-call", title: "Abraham's Call", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 12, startVerse: 1, endChapter: 12, endVerse: 9),
        Story(id: "isaac-sacrifice", title: "Abraham and Isaac", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 22, startVerse: 1, endChapter: 22, endVerse: 19),
        Story(id: "jacob-esau", title: "Jacob and Esau's Birthright", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 25, startVerse: 19, endChapter: 25, endVerse: 34),
        Story(id: "joseph-sold", title: "Joseph Sold Into Slavery", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 37, startVerse: 1, endChapter: 37, endVerse: 36),
        Story(id: "joseph-reconciled", title: "Joseph Reconciles With His Brothers", testament: "OT", bookOrder: 1, book: "Genesis", startChapter: 45, startVerse: 1, endChapter: 45, endVerse: 15),
        Story(id: "burning-bush", title: "Moses and the Burning Bush", testament: "OT", bookOrder: 2, book: "Exodus", startChapter: 3, startVerse: 1, endChapter: 4, endVerse: 17),
        Story(id: "passover", title: "The First Passover", testament: "OT", bookOrder: 2, book: "Exodus", startChapter: 12, startVerse: 1, endChapter: 12, endVerse: 32),
        Story(id: "red-sea", title: "Crossing the Red Sea", testament: "OT", bookOrder: 2, book: "Exodus", startChapter: 14, startVerse: 1, endChapter: 14, endVerse: 31),
        Story(id: "ten-commandments", title: "The Ten Commandments", testament: "OT", bookOrder: 2, book: "Exodus", startChapter: 20, startVerse: 1, endChapter: 20, endVerse: 21),
        Story(id: "jericho", title: "The Battle of Jericho", testament: "OT", bookOrder: 6, book: "Joshua", startChapter: 6, startVerse: 1, endChapter: 6, endVerse: 20),
        Story(id: "ruth", title: "Ruth and Naomi", testament: "OT", bookOrder: 8, book: "Ruth", startChapter: 1, startVerse: 1, endChapter: 4, endVerse: 22),
        Story(id: "david-goliath", title: "David and Goliath", testament: "OT", bookOrder: 9, book: "I Samuel", startChapter: 17, startVerse: 1, endChapter: 17, endVerse: 51),
        Story(id: "david-bathsheba", title: "David and Bathsheba", testament: "OT", bookOrder: 10, book: "II Samuel", startChapter: 11, startVerse: 1, endChapter: 11, endVerse: 27),
        Story(id: "solomons-wisdom", title: "Solomon's Wisdom", testament: "OT", bookOrder: 11, book: "I Kings", startChapter: 3, startVerse: 16, endChapter: 3, endVerse: 28),
        Story(id: "elijah-baal", title: "Elijah and the Prophets of Baal", testament: "OT", bookOrder: 11, book: "I Kings", startChapter: 18, startVerse: 16, endChapter: 18, endVerse: 40),
        Story(id: "daniel-lions", title: "Daniel in the Lions' Den", testament: "OT", bookOrder: 27, book: "Daniel", startChapter: 6, startVerse: 1, endChapter: 6, endVerse: 28),
        Story(id: "jonah", title: "Jonah and the Great Fish", testament: "OT", bookOrder: 32, book: "Jonah", startChapter: 1, startVerse: 1, endChapter: 2, endVerse: 10),
        Story(id: "nativity", title: "The Nativity", testament: "NT", bookOrder: 42, book: "Luke", startChapter: 2, startVerse: 1, endChapter: 2, endVerse: 20),
        Story(id: "baptism", title: "The Baptism of Jesus", testament: "NT", bookOrder: 40, book: "Matthew", startChapter: 3, startVerse: 13, endChapter: 3, endVerse: 17),
        Story(id: "temptation", title: "The Temptation of Jesus", testament: "NT", bookOrder: 40, book: "Matthew", startChapter: 4, startVerse: 1, endChapter: 4, endVerse: 11),
        Story(id: "beatitudes", title: "The Beatitudes", testament: "NT", bookOrder: 40, book: "Matthew", startChapter: 5, startVerse: 1, endChapter: 5, endVerse: 12),
        Story(id: "feeding-5000", title: "Feeding the Five Thousand", testament: "NT", bookOrder: 43, book: "John", startChapter: 6, startVerse: 1, endChapter: 6, endVerse: 14),
        Story(id: "prodigal-son", title: "The Prodigal Son", testament: "NT", bookOrder: 42, book: "Luke", startChapter: 15, startVerse: 11, endChapter: 15, endVerse: 32),
        Story(id: "good-samaritan", title: "The Good Samaritan", testament: "NT", bookOrder: 42, book: "Luke", startChapter: 10, startVerse: 25, endChapter: 10, endVerse: 37),
        Story(id: "calms-storm", title: "Jesus Calms the Storm", testament: "NT", bookOrder: 41, book: "Mark", startChapter: 4, startVerse: 35, endChapter: 4, endVerse: 41),
        Story(id: "crucifixion", title: "The Crucifixion", testament: "NT", bookOrder: 42, book: "Luke", startChapter: 23, startVerse: 32, endChapter: 23, endVerse: 49),
        Story(id: "resurrection", title: "The Resurrection", testament: "NT", bookOrder: 42, book: "Luke", startChapter: 24, startVerse: 1, endChapter: 24, endVerse: 12),
        Story(id: "great-commission", title: "The Great Commission", testament: "NT", bookOrder: 40, book: "Matthew", startChapter: 28, startVerse: 16, endChapter: 28, endVerse: 20),
        Story(id: "pentecost", title: "Pentecost", testament: "NT", bookOrder: 44, book: "Acts", startChapter: 2, startVerse: 1, endChapter: 2, endVerse: 41),
        Story(id: "pauls-conversion", title: "Paul's Conversion", testament: "NT", bookOrder: 44, book: "Acts", startChapter: 9, startVerse: 1, endChapter: 9, endVerse: 19),
    ]
}
