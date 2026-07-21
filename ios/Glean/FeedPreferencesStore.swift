import Foundation
import GleanSelection
import ScriptureCore

/// What the person wants mixed into Feed, on top of the default formation pack.
/// Stories tab is a selection surface for these prefs — not a separate reader.
final class FeedPreferencesStore: ObservableObject {
    private static let themesKey = "glean.feed.selectedThemes.v1"
    private static let storiesKey = "glean.feed.selectedStoryIDs.v1"
    /// When stories are selected, roughly this fraction of flips come from them.
    private static let storyMixProbability = 0.45

    @Published private(set) var selectedThemeRaws: Set<String> {
        didSet { persistThemes() }
    }

    @Published private(set) var selectedStoryIDs: Set<String> {
        didSet { persistStories() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.themesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            selectedThemeRaws = decoded
        } else {
            selectedThemeRaws = []
        }

        if let data = UserDefaults.standard.data(forKey: Self.storiesKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            selectedStoryIDs = decoded
        } else {
            selectedStoryIDs = []
        }
    }

    // MARK: - Themes (formation vocabulary)

    var preferredThemes: [Theme] {
        Theme.allCases.filter { selectedThemeRaws.contains($0.rawValue) }
    }

    func isThemeSelected(_ theme: Theme) -> Bool {
        selectedThemeRaws.contains(theme.rawValue)
    }

    func toggleTheme(_ theme: Theme) {
        if selectedThemeRaws.contains(theme.rawValue) {
            selectedThemeRaws.remove(theme.rawValue)
        } else {
            selectedThemeRaws.insert(theme.rawValue)
        }
    }

    // MARK: - Stories (narrative arcs mixed into feed)

    func isStorySelected(_ story: Story) -> Bool {
        selectedStoryIDs.contains(story.id)
    }

    func toggleStory(_ story: Story) {
        if selectedStoryIDs.contains(story.id) {
            selectedStoryIDs.remove(story.id)
        } else {
            selectedStoryIDs.insert(story.id)
        }
    }

    func selectAllStories(in testament: String) {
        let ids = Story.core.filter { $0.testament == testament }.map(\.id)
        selectedStoryIDs.formUnion(ids)
    }

    func clearStories(in testament: String) {
        let ids = Set(Story.core.filter { $0.testament == testament }.map(\.id))
        selectedStoryIDs.subtract(ids)
    }

    func clearAll() {
        selectedThemeRaws = []
        selectedStoryIDs = []
    }

    var selectionSummary: String {
        let t = preferredThemes.count
        let s = selectedStoryIDs.count
        switch (t, s) {
        case (0, 0):
            return "Formation pack only"
        case (_, 0):
            return "\(t) theme\(t == 1 ? "" : "s") · formation pack"
        case (0, _):
            return "\(s) stor\(s == 1 ? "y" : "ies") · formation pack"
        default:
            return "\(t) theme\(t == 1 ? "" : "s") · \(s) stor\(s == 1 ? "y" : "ies") · formation"
        }
    }

    /// Whether the next flip should try a selected story before formation.
    func shouldDrawFromStories(rng: () -> Double = { Double.random(in: 0..<1) }) -> Bool {
        guard !selectedStoryIDs.isEmpty else { return false }
        return rng() < Self.storyMixProbability
    }

    var selectedStories: [Story] {
        Story.core.filter { selectedStoryIDs.contains($0.id) }
    }

    // MARK: - Persist

    private func persistThemes() {
        if let data = try? JSONEncoder().encode(selectedThemeRaws) {
            UserDefaults.standard.set(data, forKey: Self.themesKey)
        }
    }

    private func persistStories() {
        if let data = try? JSONEncoder().encode(selectedStoryIDs) {
            UserDefaults.standard.set(data, forKey: Self.storiesKey)
        }
    }
}

// MARK: - Display helpers

extension Theme {
    var displayName: String {
        switch self {
        case .hope: return "Hope"
        case .faith: return "Faith"
        case .love: return "Love"
        case .wisdom: return "Wisdom"
        case .prayer: return "Prayer"
        case .repentance: return "Repentance"
        case .suffering: return "Suffering"
        case .joy: return "Joy"
        case .justice: return "Justice"
        case .creation: return "Creation"
        case .kingdom: return "Kingdom"
        case .identity: return "Identity"
        case .peace: return "Peace"
        }
    }

    var blurb: String {
        switch self {
        case .hope: return "Promise, waiting, future grace"
        case .faith: return "Trust that moves"
        case .love: return "God’s love and ours"
        case .wisdom: return "Skill for living before God"
        case .prayer: return "Speaking and listening to God"
        case .repentance: return "Turning home"
        case .suffering: return "Pain held with God"
        case .joy: return "Gladness rooted in God"
        case .justice: return "Defense of the crushed"
        case .creation: return "World as gift"
        case .kingdom: return "God’s reign breaking in"
        case .identity: return "Who you are in God"
        case .peace: return "Shalom / guarded heart"
        }
    }

    var symbolName: String {
        switch self {
        case .hope: return "sunrise"
        case .faith: return "figure.walk"
        case .love: return "heart"
        case .wisdom: return "lightbulb"
        case .prayer: return "hands.sparkles"
        case .repentance: return "arrow.uturn.backward"
        case .suffering: return "cloud.rain"
        case .joy: return "face.smiling"
        case .justice: return "scalemass"
        case .creation: return "globe.americas"
        case .kingdom: return "crown"
        case .identity: return "person.crop.circle"
        case .peace: return "leaf"
        }
    }
}
