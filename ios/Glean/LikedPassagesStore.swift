import Foundation

/// Local-only “likes” — no account, no cloud, no streaks.
/// Just a personal heart so a passage can be remembered on this device.
final class LikedPassagesStore: ObservableObject {
    private static let key = "glean.likedPassageIDs.v1"

    @Published private(set) var likedIDs: Set<String>

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            likedIDs = decoded
        } else {
            likedIDs = []
        }
    }

    func isLiked(_ id: String) -> Bool {
        likedIDs.contains(id)
    }

    func toggle(_ id: String) {
        if likedIDs.contains(id) {
            likedIDs.remove(id)
        } else {
            likedIDs.insert(id)
        }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(likedIDs) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}
