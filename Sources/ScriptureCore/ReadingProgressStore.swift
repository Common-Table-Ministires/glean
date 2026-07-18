import Foundation

/// Remembers which story was last opened and how far into it the reader got,
/// so leaving Stories (switching tabs, or quitting the app) and coming back
/// resumes in place rather than dropping back to the list. Same UserDefaults-
/// backed pattern as NotesStore, for the same reason: local-only, no account,
/// small enough volume that a database table isn't needed yet.
public final class ReadingProgressStore: ObservableObject {
    private static let indexKey = "scriptureapp.storyProgress.v1"
    private static let lastStoryKey = "scriptureapp.lastStoryID.v1"

    @Published public private(set) var indexByStoryID: [String: Int]
    @Published public private(set) var lastStoryID: String?

    public init() {
        if let data = UserDefaults.standard.data(forKey: Self.indexKey),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            indexByStoryID = decoded
        } else {
            indexByStoryID = [:]
        }
        lastStoryID = UserDefaults.standard.string(forKey: Self.lastStoryKey)
    }

    public func index(for storyID: String) -> Int {
        indexByStoryID[storyID] ?? 0
    }

    public func setIndex(_ index: Int, for storyID: String) {
        indexByStoryID[storyID] = index
        guard let data = try? JSONEncoder().encode(indexByStoryID) else { return }
        UserDefaults.standard.set(data, forKey: Self.indexKey)
    }

    public func setLastStoryID(_ id: String) {
        lastStoryID = id
        UserDefaults.standard.set(id, forKey: Self.lastStoryKey)
    }
}
