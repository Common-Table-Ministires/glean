import SwiftUI

final class ReaderSettings: ObservableObject {
    @AppStorage("readerFontScale") var fontScale: Double = 1.0
    @AppStorage("readerUseDyslexicFont") var useDyslexicFont: Bool = false

    static let baseFontSize: CGFloat = 22
    static let scaleSteps: [Double] = [0.8, 0.9, 1.0, 1.15, 1.3, 1.5, 1.75]

    var bodyFontSize: CGFloat {
        Self.baseFontSize * fontScale
    }

    func bodyFont() -> Font {
        if useDyslexicFont {
            return .custom("OpenDyslexic-Regular", size: bodyFontSize)
        }
        return .system(size: bodyFontSize, design: .serif)
    }

    func increaseFontSize() {
        if let next = Self.scaleSteps.first(where: { $0 > fontScale }) {
            fontScale = next
        }
    }

    func decreaseFontSize() {
        if let previous = Self.scaleSteps.last(where: { $0 < fontScale }) {
            fontScale = previous
        }
    }
}
