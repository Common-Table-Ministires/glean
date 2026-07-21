import SwiftUI
import ScriptureCore
import GleanSelection
import GleanCommentary

/// Instagram / Reels-style vertical swipe feed.
/// Selection still comes only from GleanSelection — this file is pure UX.
///
/// **Front page (swipe):** one formation **segment** (~40–120 words) — flip, flip, flip.
/// **Back page (tap):** neighbors before/after the unit + open voices + reflection.
struct FeedView: View {
    let store: ScriptureStore
    @Binding var translation: BibleTranslation

    @EnvironmentObject private var readerSettings: ReaderSettings
    @EnvironmentObject private var feedPreferences: FeedPreferencesStore
    @EnvironmentObject private var studyNavigator: StudyNavigator
    @Environment(\.appTheme) private var theme

    @StateObject private var likes = LikedPassagesStore()
    @State private var session: GleanFeedSession?
    @State private var passages: [FeedPassage] = []
    @State private var currentID: String?
    @State private var usingFallback = false
    @State private var loadError: String?
    @State private var showHeartBurst = false
    /// Context “page behind” the current flip card.
    @State private var openedPassage: FeedPassage?

    var body: some View {
        GeometryReader { geo in
            let pageHeight = max(geo.size.height, 1.0)

            ZStack {
                theme.background.ignoresSafeArea()

                if passages.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 0) {
                            ForEach(passages) { passage in
                                FeedFocusPage(
                                    passage: passage,
                                    likes: likes,
                                    pageHeight: pageHeight,
                                    onLiked: { pulseHeart() },
                                    onOpenContext: {
                                        openedPassage = passage
                                    },
                                    onOpenInStudy: {
                                        openInStudy(passage)
                                    }
                                )
                                .id(passage.id)
                                .frame(width: geo.size.width, height: pageHeight)
                                .onAppear {
                                    prefetchIfNeeded(for: passage)
                                }
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $currentID)
                    .scrollIndicators(.hidden)
                    // While context is open, don't let the feed steal swipes.
                    .allowsHitTesting(openedPassage == nil)
                }

                if showHeartBurst {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 88))
                        .foregroundStyle(theme.like.opacity(0.9))
                        .shadow(radius: 8)
                        .transition(.scale.combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.chrome, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text("Glean")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)
                    Text(feedSubtitle)
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .fullScreenCover(item: $openedPassage) { passage in
            FeedContextPage(
                passage: passage,
                likes: likes,
                onClose: { openedPassage = nil },
                onLiked: { pulseHeart() }
            )
            .environmentObject(readerSettings)
            .appTheme(readerSettings.palette, typography: readerSettings.typography)
        }
        .onAppear {
            ensureSession()
            syncSessionPreferences()
            primeFeedIfNeeded()
        }
        .onChange(of: translation) {
            passages = []
            currentID = nil
            openedPassage = nil
            primeFeedIfNeeded()
        }
        .onChange(of: feedPreferences.selectedThemeRaws) {
            syncSessionPreferences()
        }
        .onChange(of: feedPreferences.selectedStoryIDs) {
            // New stories join on the next flips; no need to wipe history.
        }
    }

    private var feedSubtitle: String {
        if usingFallback { return "offline random" }
        let mix = feedPreferences.selectionSummary
        if mix == "Formation pack only" { return "formation" }
        return mix
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            if let loadError {
                Image(systemName: "exclamationmark.bubble")
                    .font(.largeTitle)
                    .foregroundStyle(theme.secondaryText)
                Text(loadError)
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button("Try again") {
                    retryLoad()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.accent)
            } else {
                ProgressView()
                    .tint(theme.accent)
                Text("Gathering a passage…")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func pulseHeart() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
            showHeartBurst = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.25)) {
                showHeartBurst = false
            }
        }
    }

    private func ensureSession() {
        guard session == nil else { return }
        do {
            // continuousFeed: pack stays usable; long cooldowns caused "offline random"
            session = try GleanFeedSession(
                config: .continuousFeed,
                preferredThemes: feedPreferences.preferredThemes
            )
            usingFallback = false
        } catch {
            usingFallback = true
        }
    }

    private func syncSessionPreferences() {
        session?.preferredThemes = feedPreferences.preferredThemes
    }

    private func primeFeedIfNeeded() {
        guard passages.isEmpty else { return }
        appendNext()
        appendNext()
        appendNext()
        currentID = passages.first?.id
    }

    private func retryLoad() {
        loadError = nil
        session = nil
        ensureSession()
        appendNext()
        currentID = passages.first?.id
    }

    private func prefetchIfNeeded(for passage: FeedPassage) {
        let nearEnd = passages.suffix(2).contains(where: { $0.id == passage.id })
        if nearEnd {
            appendNext()
        }
    }

    private func appendNext() {
        // 1) Formation pack is the product. 2) Optional story mix. 3) SQLite last.
        let tryStoryFirst = feedPreferences.shouldDrawFromStories()

        if tryStoryFirst, let storyPassage = nextStoryPassage() {
            appendPassage(storyPassage)
            return
        }

        if let formation = nextFormationPassage() {
            appendPassage(formation)
            return
        }

        // Story second chance if formation failed
        if !tryStoryFirst, let storyPassage = nextStoryPassage() {
            appendPassage(storyPassage)
            return
        }

        // Last resort only — should be rare with continuousFeed
        if let chunk = store.randomChunk(translation: translation) {
            let unique = String(UUID().uuidString.prefix(6))
            let passage = FeedPassageBuilder.build(
                chunk: chunk,
                translation: translation,
                uniqueSuffix: unique
            )
            appendPassage(passage)
            usingFallback = true
        } else if passages.isEmpty {
            loadError = "No passages available right now."
        }
    }

    private func nextFormationPassage() -> FeedPassage? {
        ensureSession()
        syncSessionPreferences()
        guard let activeSession = session, let chunk = activeSession.next() else {
            return nil
        }
        usingFallback = false
        return FeedPassageBuilder.build(
            chunk: chunk,
            store: store,
            translation: translation
        )
    }

    /// Segment card from a selected story arc (same length rules as formation units).
    private func nextStoryPassage() -> FeedPassage? {
        let stories = feedPreferences.selectedStories
        guard let story = stories.randomElement() else { return nil }

        let chunks = store.chunks(for: story, translation: translation)
        // Prefer mid-sized chunks (~40+ words) when possible
        let ranked = chunks.sorted {
            abs($0.text.split(whereSeparator: \.isWhitespace).count - 80)
                < abs($1.text.split(whereSeparator: \.isWhitespace).count - 80)
        }
        guard let chunk = ranked.first ?? chunks.randomElement() else { return nil }

        let unique = String(UUID().uuidString.prefix(6))
        var passage = FeedPassageBuilder.build(
            chunk: chunk,
            translation: translation,
            uniqueSuffix: "story.\(story.id).\(unique)"
        )
        passage = FeedPassage(
            id: "story.\(story.id).\(chunk.chapter).\(chunk.verseRange.lowerBound).\(unique)",
            reference: passage.reference,
            focusReference: passage.focusReference,
            focusText: passage.focusText,
            focusVerse: passage.focusVerse,
            contextBefore: passage.contextBefore,
            contextAfter: passage.contextAfter,
            text: passage.text,
            verseCount: passage.verseCount,
            wordCount: passage.wordCount,
            translation: passage.translation,
            theology: passage.theology
        )
        usingFallback = false
        return passage
    }

    private func appendPassage(_ passage: FeedPassage) {
        if !passages.contains(where: { $0.id == passage.id }) {
            passages.append(passage)
            trimBufferIfNeeded()
            return
        }
        // Avoid stalling on duplicate id
        if let alt = nextFormationPassage(),
           !passages.contains(where: { $0.id == alt.id }) {
            passages.append(alt)
            trimBufferIfNeeded()
        }
    }

    private func trimBufferIfNeeded() {
        let maxBuffered = 80
        guard passages.count > maxBuffered else { return }

        let dropCount = passages.count - maxBuffered
        var start = dropCount
        if let currentID,
           let idx = passages.firstIndex(where: { $0.id == currentID }) {
            start = min(dropCount, max(0, idx - 5))
        }
        if start > 0 {
            passages.removeFirst(start)
        }
    }

    /// Jump the Study tab to this segment’s anchor verse.
    private func openInStudy(_ passage: FeedPassage) {
        guard let loc = Self.resolveStudyLocation(passage: passage, store: store) else { return }
        studyNavigator.openStudy(bookOrder: loc.bookOrder, chapter: loc.chapter, verse: loc.verse)
    }

    static func resolveStudyLocation(
        passage: FeedPassage,
        store: ScriptureStore
    ) -> (bookOrder: Int, chapter: Int, verse: Int)? {
        let parsed = FeedFocusPage.parseFocusReference(passage.focusReference)
            ?? FeedFocusPage.parseFocusReference(passage.reference)
        guard let parsed else { return nil }

        let books = store.allBooks()
        let bookOrder =
            books.first(where: { $0.name == parsed.book })?.bookOrder
            ?? books.first(where: {
                $0.name.caseInsensitiveCompare(parsed.book) == .orderedSame
            })?.bookOrder
            ?? books.first(where: {
                // "Psalm" vs "Psalms"
                $0.name.hasPrefix(parsed.book) || parsed.book.hasPrefix($0.name)
            })?.bookOrder

        guard let bookOrder else { return nil }
        let verse = passage.focusVerse ?? parsed.verse
        return (bookOrder, parsed.chapter, verse)
    }
}

// MARK: - Front card (swipe / flip only)

/// Full-screen formation **segment** (spec ~40–120 words). Neighbors + voices on tap.
private struct FeedFocusPage: View {
    let passage: FeedPassage
    @ObservedObject var likes: LikedPassagesStore
    let pageHeight: CGFloat
    var onLiked: () -> Void
    var onOpenContext: () -> Void
    var onOpenInStudy: () -> Void

    @EnvironmentObject private var readerSettings: ReaderSettings
    @Environment(\.appTheme) private var theme

    private var isLiked: Bool { likes.isLiked(passage.id) }

    private var openCommentary: [CommentaryExcerpt] {
        Self.commentaryExcerpts(for: passage)
    }

    private var canOpenContext: Bool {
        passage.hasContext || passage.theology != nil || !openCommentary.isEmpty
    }

    private var shareText: String {
        "\(passage.focusReference)\n\n\(passage.focusText)\n\n— via Glean"
    }

    private var metaLine: String {
        let v = passage.verseCount
        let verseWord = v == 1 ? "verse" : "verses"
        return "\(v) \(verseWord) · \(passage.wordCount) words"
    }

    /// Shared lookup used by focus + context pages.
    static func commentaryExcerpts(for passage: FeedPassage) -> [CommentaryExcerpt] {
        let packId: String? = {
            let id = passage.id
            if id.hasPrefix("story.") || id.hasPrefix("fallback.") { return nil }
            if id.contains(".") { return id }
            return nil
        }()
        let parsed = parseFocusReference(passage.focusReference)
        return CommentaryStore.shared.excerpts(
            packId: packId,
            focusReference: passage.focusReference,
            book: parsed?.book,
            chapter: parsed?.chapter,
            verse: passage.focusVerse ?? parsed?.verse,
            limit: 4
        )
    }

    static func parseFocusReference(_ ref: String) -> (book: String, chapter: Int, verse: Int)? {
        // "John 3:16", "John 3:16-17", "1 Corinthians 13:4"
        guard let colon = ref.lastIndex(of: ":") else { return nil }
        let versePart = ref[ref.index(after: colon)...]
        let verseNum = versePart.split(whereSeparator: { !$0.isNumber }).first.map(String.init).flatMap(Int.init)
        let head = String(ref[..<colon]).trimmingCharacters(in: .whitespaces)
        guard let space = head.lastIndex(of: " "),
              let chapter = Int(head[head.index(after: space)...].trimmingCharacters(in: .whitespaces)),
              let verseNum
        else { return nil }
        let book = String(head[..<space]).trimmingCharacters(in: .whitespaces)
        guard !book.isEmpty else { return nil }
        return (book, chapter, verseNum)
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            VStack(spacing: 0) {
                Spacer(minLength: 16)

                // Segment may be 80–120 words — allow gentle scroll *inside* the card
                // only if needed; paging still owns the vertical flip between cards.
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(passage.focusReference.uppercased())
                            .font(readerSettings.referenceFont(size: 13))
                            .foregroundStyle(theme.accent)
                            .tracking(0.8)

                        Text(passage.focusText)
                            .font(readerSettings.bodyFont())
                            .foregroundStyle(theme.primaryText)
                            .lineSpacing(readerSettings.bodyFontSize * 0.38)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(metaLine)
                            .font(.caption)
                            .foregroundStyle(theme.tertiaryText)

                        if canOpenContext {
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.on.rectangle")
                                    .font(.caption2)
                                Text("Tap for neighbors & voices")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundStyle(theme.secondaryText)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.trailing, 48)
                    .padding(.vertical, 8)
                    .frame(maxWidth: 560, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)

                HStack(spacing: 6) {
                    Image(systemName: "chevron.compact.up")
                    Text("Swipe up for next")
                }
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
                .padding(.bottom, 72)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            actionRail
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if !isLiked {
                likes.toggle(passage.id)
            }
            onLiked()
        }
        .onTapGesture(count: 1) {
            guard canOpenContext else { return }
            onOpenContext()
        }
        .frame(height: pageHeight)
        .background(theme.background)
    }

    private var actionRail: some View {
        VStack(spacing: 18) {
            Spacer()

            Button {
                let wasLiked = isLiked
                likes.toggle(passage.id)
                if !wasLiked { onLiked() }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 28))
                        .symbolEffect(.bounce, value: isLiked)
                        .foregroundStyle(isLiked ? theme.like : theme.primaryText)
                    Text(isLiked ? "Liked" : "Like")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            ShareLink(item: shareText) {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 26))
                        .foregroundStyle(theme.primaryText)
                    Text("Share")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            // Under heart + share: open this segment in Study
            Button(action: onOpenInStudy) {
                VStack(spacing: 4) {
                    Image(systemName: "highlighter")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.primaryText)
                    Text("Study")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .buttonStyle(.plain)

            if canOpenContext {
                Button(action: onOpenContext) {
                    VStack(spacing: 4) {
                        Image(systemName: "text.justify.left")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.primaryText)
                        Text("Open")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryText)
                    }
                }
                .buttonStyle(.plain)
            }

            // Clear the floating tab bar / center button so the rail stays tappable
            Spacer()
                .frame(height: 96)
        }
        .padding(.trailing, 14)
        .padding(.bottom, 36)
    }
}

// MARK: - Back page (context + theology)

/// Separate full-screen page: surrounding verses + signed reflection.
/// Dismiss to return to flip-flip-flip.
private struct FeedContextPage: View {
    let passage: FeedPassage
    @ObservedObject var likes: LikedPassagesStore
    var onClose: () -> Void
    var onLiked: () -> Void

    @EnvironmentObject private var readerSettings: ReaderSettings
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    private var isLiked: Bool { likes.isLiked(passage.id) }

    private var openCommentary: [CommentaryExcerpt] {
        FeedFocusPage.commentaryExcerpts(for: passage)
    }

    private var shareText: String {
        var parts = ["\(passage.focusReference)\n\n\(passage.focusText)"]
        if passage.hasContext {
            parts.append("\n\n— \(passage.reference) —\n\(passage.text)")
        }
        for excerpt in openCommentary {
            parts.append(
                "\n\n\(excerpt.note.text)\n— \(excerpt.authorLine) (\(excerpt.note.confidence.displayName))"
            )
        }
        if let theology = passage.theology {
            parts.append("\n\n\(theology.body)\n(\(theology.source) · \(theology.confidence.rawValue))")
        }
        parts.append("\n\n— via Glean")
        return parts.joined()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    // Reading order: before → segment → after
                    if !passage.contextBefore.isEmpty {
                        contextSection(title: "Before", lines: passage.contextBefore)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("THIS PASSAGE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(theme.accent)
                            .tracking(1.2)

                        Text(passage.focusReference.uppercased())
                            .font(readerSettings.referenceFont(size: 13))
                            .foregroundStyle(theme.accent)
                            .tracking(0.6)

                        Text(passage.focusText)
                            .font(readerSettings.bodyFont())
                            .foregroundStyle(theme.primaryText)
                            .lineSpacing(readerSettings.bodyFontSize * 0.35)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(theme.card.opacity(0.65))
                    )

                    if !passage.contextAfter.isEmpty {
                        contextSection(title: "After", lines: passage.contextAfter)
                    }

                    if !passage.hasContext {
                        Text("No extra neighbor verses around this unit.")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                    }

                    // Open / public-domain voices (GleanCommentary)
                    if !openCommentary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VOICES")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(theme.tertiaryText)
                                .tracking(1.0)

                            ForEach(openCommentary) { excerpt in
                                openCommentaryCard(excerpt)
                            }

                            Text("Public-domain excerpts · not the words of Scripture")
                                .font(.caption2)
                                .foregroundStyle(theme.tertiaryText)
                        }
                    }

                    // CTM ministry reflection (signed personal / curated)
                    if let theology = passage.theology {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                    .font(.caption)
                                Text("Reflection")
                                    .font(.subheadline.weight(.semibold))
                                Text("·")
                                    .foregroundStyle(theme.tertiaryText)
                                Text(theology.confidence.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(theme.tertiaryText)
                            }
                            .foregroundStyle(theme.accent)

                            Text(theology.body)
                                .font(.system(size: 16, weight: .regular, design: .serif))
                                .foregroundStyle(theme.secondaryText)
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(theology.source)
                                .font(.caption)
                                .foregroundStyle(theme.tertiaryText)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(theme.accent.opacity(0.35), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(theme.card.opacity(0.45))
                                )
                        )
                    }

                    Text(passage.reference)
                        .font(.caption2)
                        .foregroundStyle(theme.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(theme.background.ignoresSafeArea())
            .navigationTitle("Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onClose()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.title3)
                            .foregroundStyle(theme.secondaryText)
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        let wasLiked = isLiked
                        likes.toggle(passage.id)
                        if !wasLiked { onLiked() }
                    } label: {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? theme.like : theme.primaryText)
                    }
                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .toolbarBackground(theme.chrome, for: .navigationBar)
        }
        .presentationBackground(theme.background)
    }

    private func contextSection(title: String, lines: [FeedVerseLine]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(theme.tertiaryText)
                .tracking(1.0)

            ForEach(lines, id: \.verse) { line in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(line.verse)")
                        .font(readerSettings.referenceFont(size: 12))
                        .foregroundStyle(theme.tertiaryText)
                        .frame(width: 28, alignment: .trailing)
                    Text(line.text)
                        .font(readerSettings.bodyFont())
                        .foregroundStyle(theme.secondaryText)
                        .lineSpacing(readerSettings.bodyFontSize * 0.28)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.card.opacity(0.4))
        )
    }

    private func openCommentaryCard(_ excerpt: CommentaryExcerpt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "books.vertical")
                    .font(.caption)
                Text(excerpt.source.author)
                    .font(.subheadline.weight(.semibold))
                Text("·")
                    .foregroundStyle(theme.tertiaryText)
                Text(excerpt.note.confidence.displayName)
                    .font(.caption)
                    .foregroundStyle(theme.tertiaryText)
            }
            .foregroundStyle(theme.accent)

            Text(excerpt.note.text)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(theme.secondaryText)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text(excerpt.traditionLine)
                .font(.caption2)
                .foregroundStyle(theme.tertiaryText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.card.opacity(0.4))
        )
    }
}
