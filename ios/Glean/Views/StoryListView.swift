import SwiftUI
import ScriptureCore
import GleanSelection

/// Selection surface for what mixes into Feed — not a sequential story reader.
/// Pick formation themes and narrative stories; Feed still always includes the
/// formational pack, with your choices weighted in.
struct StoryListView: View {
    let store: ScriptureStore
    let translation: BibleTranslation

    @EnvironmentObject private var readerSettings: ReaderSettings
    @EnvironmentObject private var feedPreferences: FeedPreferencesStore
    @Environment(\.appTheme) private var theme

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shape your feed")
                            .font(.headline)
                            .foregroundStyle(theme.primaryText)
                        Text("Flip through focus verses in Feed. Whatever you select here is mixed in with the formational pack — not instead of it.")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(feedPreferences.selectionSummary)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.accent)
                            .padding(.top, 2)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(theme.card.opacity(0.5))
                }

                Section {
                    ForEach(Theme.allCases, id: \.self) { themeItem in
                        themeRow(themeItem)
                    }
                } header: {
                    Text("Topics (formation)")
                } footer: {
                    Text("Nudges the formational algorithm toward these themes when scoring passages.")
                }

                Section {
                    testamentControls(testament: "OT", title: "Old Testament")
                    ForEach(Story.core.filter { $0.testament == "OT" }) { story in
                        storyRow(story)
                    }
                } header: {
                    Text("Stories · Old Testament")
                }

                Section {
                    testamentControls(testament: "NT", title: "New Testament")
                    ForEach(Story.core.filter { $0.testament == "NT" }) { story in
                        storyRow(story)
                    }
                } header: {
                    Text("Stories · New Testament")
                } footer: {
                    Text("Selected stories contribute focus-verse cards in Feed (same tap-for-context action as formation flips).")
                }

                if !feedPreferences.selectedThemeRaws.isEmpty || !feedPreferences.selectedStoryIDs.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            feedPreferences.clearAll()
                        } label: {
                            Label("Clear all selections", systemImage: "xmark.circle")
                        }
                    }
                }
            }
            .scrollContentBackground(readerSettings.themeID == .system ? .automatic : .hidden)
            .background(theme.background)
            .navigationTitle("Stories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text("\(feedPreferences.selectedStoryIDs.count + feedPreferences.preferredThemes.count)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(theme.accent.opacity(0.15)))
                        .accessibilityLabel("\(feedPreferences.selectedStoryIDs.count) stories and \(feedPreferences.preferredThemes.count) themes selected")
                }
            }
        }
    }

    // MARK: - Rows

    private func themeRow(_ item: Theme) -> some View {
        let on = feedPreferences.isThemeSelected(item)
        return Button {
            feedPreferences.toggleTheme(item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.symbolName)
                    .font(.body)
                    .foregroundStyle(on ? theme.accent : theme.secondaryText)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.displayName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(theme.primaryText)
                    Text(item.blurb)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(on ? theme.accent : theme.tertiaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(on ? theme.accent.opacity(0.08) : nil)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func storyRow(_ story: Story) -> some View {
        let on = feedPreferences.isStorySelected(story)
        return Button {
            feedPreferences.toggleStory(story)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(story.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(theme.primaryText)
                        .multilineTextAlignment(.leading)
                    Text(storyRangeLabel(story))
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(on ? theme.accent : theme.tertiaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(on ? theme.accent.opacity(0.08) : nil)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func testamentControls(testament: String, title: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
            Spacer()
            Button("All") {
                feedPreferences.selectAllStories(in: testament)
            }
            .font(.caption.weight(.semibold))
            Button("None") {
                feedPreferences.clearStories(in: testament)
            }
            .font(.caption.weight(.semibold))
        }
        .buttonStyle(.borderless)
    }

    private func storyRangeLabel(_ story: Story) -> String {
        if story.startChapter == story.endChapter {
            if story.startVerse == story.endVerse {
                return "\(story.book) \(story.startChapter):\(story.startVerse)"
            }
            return "\(story.book) \(story.startChapter):\(story.startVerse)–\(story.endVerse)"
        }
        return "\(story.book) \(story.startChapter):\(story.startVerse) – \(story.endChapter):\(story.endVerse)"
    }
}
