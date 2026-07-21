import Foundation

/// Persists selection history on-device without accounts, SQLite, or SwiftData.
/// Default backend is UserDefaults so the package stays dependency-free.
public final class SeenHistoryStore: @unchecked Sendable {
    public static let defaultKey = "org.commontableministries.gleanselection.seen.v1"

    private let defaults: UserDefaults
    private let key: String
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(defaults: UserDefaults = .standard, key: String = SeenHistoryStore.defaultKey) {
        self.defaults = defaults
        self.key = key
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .secondsSince1970
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .secondsSince1970
    }

    public func load() -> [SeenChunk] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? decoder.decode([SeenChunk].self, from: data)) ?? []
    }

    public func save(_ history: [SeenChunk]) {
        guard let data = try? encoder.encode(history) else { return }
        defaults.set(data, forKey: key)
    }

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}
