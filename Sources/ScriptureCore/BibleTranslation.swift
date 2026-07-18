import Foundation

public enum BibleTranslation: String, CaseIterable, Identifiable, Sendable {
    case bsb = "BSB"
    case kjv = "KJV"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bsb: return "Berean Standard Bible"
        case .kjv: return "King James Version"
        }
    }
}
