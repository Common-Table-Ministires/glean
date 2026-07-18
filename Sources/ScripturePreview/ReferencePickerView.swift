import SwiftUI
import ScriptureCore

/// Book / chapter / verse picker: a color-coded grid drill-down (books, then
/// chapters, then verses), with a sticky header that lets you jump back to any
/// level without retracing your steps. Same interaction shape as well-known
/// Bible-app pickers (a grid beats a scrolling list for 66 books), rendered with
/// our own visual language rather than copying any specific app's colors or
/// chrome.
struct ReferencePickerView: View {
    let store: ScriptureStore
    let translation: BibleTranslation
    let initialBookOrder: Int
    let initialChapter: Int
    let initialVerse: Int
    let onDone: (Int, Int, Int) -> Void

    private enum Level {
        case books, chapters, verses
    }

    @Environment(\.dismiss) private var dismiss
    @State private var level: Level = .books
    @State private var books: [BookInfo] = []
    @State private var bookOrder: Int
    @State private var chapter: Int
    @State private var verse: Int

    init(store: ScriptureStore, translation: BibleTranslation, initialBookOrder: Int, initialChapter: Int, initialVerse: Int, onDone: @escaping (Int, Int, Int) -> Void) {
        self.store = store
        self.translation = translation
        self.initialBookOrder = initialBookOrder
        self.initialChapter = initialChapter
        self.initialVerse = initialVerse
        self.onDone = onDone
        _bookOrder = State(initialValue: initialBookOrder)
        _chapter = State(initialValue: initialChapter)
        _verse = State(initialValue: initialVerse)
    }

    private var selectedBook: BookInfo? {
        books.first { $0.bookOrder == bookOrder }
    }

    private var chapterCount: Int {
        store.chapterCount(bookOrder: bookOrder, translation: translation)
    }

    private var verseCount: Int {
        store.verseCount(bookOrder: bookOrder, chapter: chapter, translation: translation)
    }

    private let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                switch level {
                case .books:
                    bookGrid
                case .chapters:
                    numberGrid(count: chapterCount, selected: chapter) { chosen in
                        chapter = chosen
                        verse = 1
                        level = .verses
                    }
                case .verses:
                    numberGrid(count: verseCount, selected: verse) { chosen in
                        verse = chosen
                        onDone(bookOrder, chapter, verse)
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 380, minHeight: 520)
        .onAppear {
            if books.isEmpty {
                books = store.allBooks()
            }
        }
    }

    private var header: some View {
        HStack {
            Button {
                switch level {
                case .books: dismiss()
                case .chapters: level = .books
                case .verses: level = .chapters
                }
            } label: {
                Image(systemName: level == .books ? "xmark" : "chevron.left")
            }
            .buttonStyle(.plain)
            .font(.system(size: 16, weight: .medium))

            Spacer()

            HStack(spacing: 10) {
                Text(selectedBook?.name ?? "")
                    .font(.headline)
                    .onTapGesture { level = .books }

                if level != .books {
                    headerPill(text: "Ch \(chapter)") { level = .chapters }
                }
                if level == .verses {
                    headerPill(text: "V \(verse)") { level = .verses }
                }
            }

            Spacer()
            Color.clear.frame(width: 16)
        }
        .padding(16)
    }

    private func headerPill(text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }

    private var bookGrid: some View {
        VStack(alignment: .leading, spacing: 18) {
            bookSection(title: "Old Testament", testament: "OT")
            bookSection(title: "New Testament", testament: "NT")
        }
        .padding(16)
    }

    private func bookSection(title: String, testament: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(books.filter { $0.testament == testament }) { book in
                    Button {
                        bookOrder = book.bookOrder
                        chapter = 1
                        verse = 1
                        level = .chapters
                    } label: {
                        Text(book.abbreviation)
                            .font(.system(size: 13, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(book.bookOrder == bookOrder ? GenreColor.color(for: book.genre) : GenreColor.color(for: book.genre).opacity(0.15))
                            )
                            .foregroundStyle(book.bookOrder == bookOrder ? Color.white : GenreColor.color(for: book.genre))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func numberGrid(count: Int, selected: Int, onPick: @escaping (Int) -> Void) -> some View {
        LazyVGrid(columns: gridColumns, spacing: 10) {
            ForEach(1...max(count, 1), id: \.self) { n in
                Button {
                    onPick(n)
                } label: {
                    Text("\(n)")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(n == selected ? Color.accentColor : Color.accentColor.opacity(0.12))
                        )
                        .foregroundStyle(n == selected ? Color.white : Color.primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
    }
}

/// Maps a book's genre to a color, purely to make the 66-book grid fast to scan.
/// Not tied to any particular app's scheme; these are our own choices.
private enum GenreColor {
    static func color(for genre: String) -> Color {
        switch genre {
        case "law": return .brown
        case "narrative": return .orange
        case "poetry": return .green
        case "prophecy": return .blue
        case "epistle": return .purple
        default: return .gray
        }
    }
}
