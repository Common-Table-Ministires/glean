import SwiftUI
import ScriptureCore
import GleanSelection

/// Feed: vertical swipe through formation passages (thin client of GleanSelection).
struct FeedView: View {
    let store: ScriptureStore
    @Binding var translation: BibleTranslation

    @State private var session: GleanFeedSession?
    @State private var passages: [FeedPassage] = []
    @State private var currentID: String?
    @State private var usingFallback = false
    @State private var loadError: String?
    @State private var likedIDs: Set<String> = []

    var body: some View {
        GeometryReader { geo in
            let pageHeight = max(geo.size.height, 400)

            ZStack {
                if passages.isEmpty {
                    if let loadError {
                        Text(loadError).foregroundStyle(.secondary)
                    } else {
                        ProgressView()
                    }
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(passages) { passage in
                                macFeedPage(
                                    passage: passage,
                                    pageHeight: pageHeight,
                                    isLiked: likedIDs.contains(passage.id),
                                    onLike: { toggleLike(passage.id) }
                                )
                                .id(passage.id)
                                .frame(height: pageHeight)
                                .onAppear {
                                    if passage.id == passages.last?.id {
                                        appendNext()
                                    }
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentID)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            ensureSession()
            if passages.isEmpty {
                appendNext()
                appendNext()
                appendNext()
                currentID = passages.first?.id
            }
        }
    }

    private func toggleLike(_ id: String) {
        if likedIDs.contains(id) {
            likedIDs.remove(id)
        } else {
            likedIDs.insert(id)
        }
    }

    private func ensureSession() {
        guard session == nil else { return }
        do {
            session = try GleanFeedSession()
            usingFallback = false
        } catch {
            usingFallback = true
        }
    }

    private func appendNext() {
        if let session, let chunk = session.next() {
            let p = FeedPassage(chunk: chunk)
            if !passages.contains(where: { $0.id == p.id }) {
                passages.append(p)
            }
            usingFallback = false
            return
        }
        if let chunk = store.randomChunk(translation: translation) {
            passages.append(FeedPassage(
                id: "fallback.\(chunk.book).\(chunk.chapter).\(chunk.verseRange.lowerBound).\(UUID().uuidString.prefix(6))",
                reference: chunk.reference,
                text: chunk.text,
                verseCount: chunk.verses.count,
                wordCount: chunk.text.split(whereSeparator: \.isWhitespace).count,
                translation: chunk.translation
            ))
            usingFallback = true
        } else if passages.isEmpty {
            loadError = "No passages available"
        }
    }
}

private struct macFeedPage: View {
    let passage: FeedPassage
    let pageHeight: CGFloat
    let isLiked: Bool
    var onLike: () -> Void
    @EnvironmentObject private var readerSettings: ReaderSettings

    private var shareText: String {
        "\(passage.reference)\n\n\(passage.text)\n\n— via Glean"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(passage.reference.uppercased())
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(passage.text)
                        .font(readerSettings.bodyFont())
                        .lineSpacing(readerSettings.bodyFontSize * 0.3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: 520, alignment: .leading)
                .padding(.horizontal, 20)
            }

            VStack(spacing: 16) {
                Button(action: onLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(isLiked ? .red : .primary)
                }
                .buttonStyle(.plain)
                .help("Like (saved on this device)")

                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                }
                .help("Share passage")
            }
            .padding(.trailing, 16)
        }
        .frame(height: pageHeight)
        .overlay(alignment: .bottom) {
            Text("Scroll / swipe for next")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
    }
}
