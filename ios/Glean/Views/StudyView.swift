import SwiftUI
import ScriptureCore

struct StudyView: View {
    let store: ScriptureStore
    let translation: BibleTranslation
    @EnvironmentObject var readerSettings: ReaderSettings
    @EnvironmentObject private var studyNavigator: StudyNavigator
    @Environment(\.appTheme) private var theme
    @StateObject private var notesStore = NotesStore()

    @AppStorage("study.bookOrder") private var bookOrder = 1
    @AppStorage("study.chapter") private var chapter = 1
    @AppStorage("study.verse") private var verse = 1
    @State private var chapterVerses: [Verse] = []
    @State private var showPicker = false
    @State private var noteText = ""
    @State private var lastJumpToken = 0

    private var bookName: String {
        chapterVerses.first?.book ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(bookName) \(chapter)")
                            .font(readerSettings.referenceFont(size: 20))
                            .foregroundStyle(theme.primaryText)
                            .padding(.bottom, 4)
                        ForEach(chapterVerses) { v in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(v.verse)")
                                    .font(readerSettings.referenceFont(size: 12))
                                    .foregroundStyle(theme.secondaryText)
                                    .frame(width: 20, alignment: .trailing)
                                Text(v.text)
                                    .font(readerSettings.bodyFont())
                                    .foregroundStyle(theme.primaryText)
                            }
                            .id(v.verse)
                            .padding(6)
                            .background(
                                v.verse == verse
                                    ? RoundedRectangle(cornerRadius: 6).fill(theme.accent.opacity(0.22))
                                    : nil
                            )
                        }
                    }
                    .padding(20)
                }
                .onChange(of: verse) {
                    withAnimation { proxy.scrollTo(verse, anchor: .center) }
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    showPicker = true
                } label: {
                    // SF Symbols has no literal sword glyph; this is the closest
                    // built-in stand-in for "find a reference."
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .padding(10)
                        .background(Circle().fill(.regularMaterial))
                        .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(14)
                .sheet(isPresented: $showPicker) {
                    ReferencePickerView(
                        store: store,
                        translation: translation,
                        initialBookOrder: bookOrder,
                        initialChapter: chapter,
                        initialVerse: verse,
                        onDone: { newBookOrder, newChapter, newVerse in
                            bookOrder = newBookOrder
                            chapter = newChapter
                            verse = newVerse
                            loadChapter()
                        }
                    )
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes on \(bookName) \(chapter):\(verse)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                TextEditor(text: $noteText)
                    .font(.system(size: 14))
                    .padding(.horizontal, 6)
                    .onChange(of: noteText) {
                        notesStore.setNote(noteText, bookOrder: bookOrder, chapter: chapter, verse: verse)
                    }
            }
            .frame(height: 160)
            .background(theme.chrome)
        }
        .background(theme.background.ignoresSafeArea())
        .onAppear {
            applyNavigatorIfNeeded(force: chapterVerses.isEmpty)
        }
        .onChange(of: translation) {
            loadChapter()
        }
        .onChange(of: verse) {
            noteText = notesStore.note(bookOrder: bookOrder, chapter: chapter, verse: verse)
        }
        .onChange(of: studyNavigator.jumpToken) {
            applyNavigatorIfNeeded(force: true)
        }
    }

    private func applyNavigatorIfNeeded(force: Bool) {
        let token = studyNavigator.jumpToken
        if force || token != lastJumpToken {
            bookOrder = studyNavigator.bookOrder
            chapter = studyNavigator.chapter
            verse = studyNavigator.verse
            lastJumpToken = token
            loadChapter()
        } else if chapterVerses.isEmpty {
            loadChapter()
        }
    }

    private func loadChapter() {
        chapterVerses = store.chapterVerses(bookOrder: bookOrder, chapter: chapter, translation: translation)
        noteText = notesStore.note(bookOrder: bookOrder, chapter: chapter, verse: verse)
    }
}
