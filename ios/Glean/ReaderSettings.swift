import SwiftUI

final class ReaderSettings: ObservableObject {
    @AppStorage("readerFontScale") var fontScale: Double = 1.0
    @AppStorage("readerUseDyslexicFont") var useDyslexicFont: Bool = false
    /// Stored as raw string so `@AppStorage` stays Codable-simple under Swift 6.
    @AppStorage("readerAppTheme") var themeIDRaw: String = AppThemeID.system.rawValue

    static let baseFontSize: CGFloat = 22
    static let scaleSteps: [Double] = [0.8, 0.9, 1.0, 1.15, 1.3, 1.5, 1.75]

    var themeID: AppThemeID {
        AppThemeID(rawValue: themeIDRaw) ?? .system
    }

    var palette: AppThemePalette {
        themeID.palette
    }

    var typography: ThemeTypography {
        themeID.typography
    }

    var bodyFontSize: CGFloat {
        Self.baseFontSize * fontScale
    }

    var canDecreaseFont: Bool {
        fontScale > (Self.scaleSteps.first ?? 0.8)
    }

    var canIncreaseFont: Bool {
        fontScale < (Self.scaleSteps.last ?? 1.75)
    }

    func setTheme(_ id: AppThemeID) {
        themeIDRaw = id.rawValue
        objectWillChange.send()
    }

    /// Scripture body — theme typeface, unless dyslexia-friendly override is on.
    func bodyFont() -> Font {
        if useDyslexicFont {
            return .custom("OpenDyslexic-Regular", size: bodyFontSize * typography.sizeMultiplier)
        }
        return typography.bodyFont(size: bodyFontSize)
    }

    /// Reference labels (e.g. “JOHN 3:16”) — matches the theme’s accent face.
    func referenceFont(size: CGFloat = 12) -> Font {
        if useDyslexicFont {
            return .custom("OpenDyslexic-Regular", size: size * typography.sizeMultiplier)
        }
        return typography.referenceFont(size: size)
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
