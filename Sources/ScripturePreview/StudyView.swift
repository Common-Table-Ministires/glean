import SwiftUI
import ScriptureCore

struct StudyView: View {
    let store: ScriptureStore
    let translation: BibleTranslation
    @EnvironmentObject var readerSettings: ReaderSettings
    @StateObject private var notesStore = NotesStore()

    // AppStorage rather than plain @State: the last-viewed reference should survive
    // both switching tabs and quitting the app, not reset to Genesis 1:1 each time.
    @AppStorage("study.bookOrder") private var bookOrder = 1
    @AppStorage("study.chapter") private var chapter = 1
    @AppStorage("study.verse") private var verse = 1
    @State private var chapterVerses: [Verse] = []
    @State private var showPicker = false
    @State private var noteText = ""

    private var bookName: String {
        chapterVerses.first?.book ?? ""
    }

    var body: some View {
        VSplitView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("\(bookName) \(chapter)")
                                .font(.title3.weight(.semibold))
                            Spacer()
                        }
                        .padding(.bottom, 4)
                        ForEach(chapterVerses) { v in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(v.verse)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20, alignment: .trailing)
                                Text(v.text)
                                    .font(readerSettings.bodyFont())
                            }
                            .id(v.verse)
                            .padding(6)
                            .background(
                                v.verse == verse
                                    ? RoundedRectangle(cornerRadius: 6).fill(Color.yellow.opacity(0.25))
                                    : nil
                            )
                        }
                    }
                    .padding(20)
                    .padding(.top, 40)
                }
                .frame(minHeight: 200)
                .onChange(of: verse) {
                    withAnimation { proxy.scrollTo(verse, anchor: .center) }
                }
                // Floating trigger lives in the content itself, not the top toolbar:
                // a toolbar button here gets buried in the overflow ">>" menu at phone
                // width, and a popover anchored to a hidden overflow item has nowhere
                // valid to appear from. This stays reachable at any window size.
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
                    .help("Find a passage")
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
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Notes on \(bookName) \(chapter):\(verse)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding([.top, .horizontal], 10)
                TextEditor(text: $noteText)
                    .font(.system(size: 14))
                    .padding(6)
                    .onChange(of: noteText) {
                        notesStore.setNote(noteText, bookOrder: bookOrder, chapter: chapter, verse: verse)
                    }
            }
            .frame(minHeight: 140)
        }
        .onAppear {
            if chapterVerses.isEmpty { loadChapter() }
        }
        .onChange(of: translation) {
            loadChapter()
        }
        .onChange(of: verse) {
            noteText = notesStore.note(bookOrder: bookOrder, chapter: chapter, verse: verse)
        }
    }

    private func loadChapter() {
        chapterVerses = store.chapterVerses(bookOrder: bookOrder, chapter: chapter, translation: translation)
        noteText = notesStore.note(bookOrder: bookOrder, chapter: chapter, verse: verse)
    }
}
