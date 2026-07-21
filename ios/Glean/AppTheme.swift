import SwiftUI
import UIKit

/// Curated visual themes for Glean. Fixed palettes + typefaces only — no theme maker.
/// Distinct from GleanSelection's formation `Theme` (hope/faith/love…); these are UI skins.
enum AppThemeID: String, CaseIterable, Identifiable, Codable, Sendable {
    case system
    // Natural
    case parchment
    case forest
    // Minimalist
    case plainLight
    case ink
    // Feminine
    case blush
    case lavender
    // Masculine
    case slate
    case navy
    // Kids
    case sunshine
    case ocean

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .parchment: return "Parchment"
        case .forest: return "Forest"
        case .plainLight: return "Plain"
        case .ink: return "Ink"
        case .blush: return "Blush"
        case .lavender: return "Lavender"
        case .slate: return "Slate"
        case .navy: return "Navy"
        case .sunshine: return "Sunshine"
        case .ocean: return "Ocean"
        }
    }

    var category: String {
        switch self {
        case .system: return "Default"
        case .parchment, .forest: return "Natural"
        case .plainLight, .ink: return "Minimalist"
        case .blush, .lavender: return "Feminine"
        case .slate, .navy: return "Masculine"
        case .sunshine, .ocean: return "Kids"
        }
    }

    var blurb: String {
        switch self {
        case .system: return "Follows your phone’s light or dark mode · system serif"
        case .parchment: return "Warm paper · Palatino, classic book pages"
        case .forest: return "Deep greens · Georgia, quiet and earthy"
        case .plainLight: return "Clean white · SF Pro, almost no color"
        case .ink: return "High-contrast dark · SF Pro Text, sharp"
        case .blush: return "Soft rose · Optima, light and graceful"
        case .lavender: return "Lilac dusk · Hoefler Text, gentle elegance"
        case .slate: return "Cool charcoal · Futura, steel geometry"
        case .navy: return "Deep blue desk · Baskerville, study classic"
        case .sunshine: return "Bright yellow · rounded letters for little readers"
        case .ocean: return "Seafoam play · Noteworthy, friendly handwriting"
        }
    }

    /// Short label for the typeface used in this theme.
    var fontDisplayName: String {
        typography.displayName
    }

    /// Swatch colors for the picker preview (left → right).
    var previewSwatches: [Color] {
        let p = palette
        return [p.background, p.card, p.accent, p.primaryText]
    }

    var typography: ThemeTypography {
        switch self {
        case .system:
            // Neutral default — New York–style reading serif via SF design.
            return ThemeTypography(
                displayName: "System Serif",
                body: .system(design: .serif, weight: .regular),
                reference: .system(design: .rounded, weight: .semibold),
                sizeMultiplier: 1.0
            )
        case .parchment:
            // Manuscript / old book feel.
            return ThemeTypography(
                displayName: "Palatino",
                body: .named("Palatino-Roman", fallback: .serif),
                reference: .named("Palatino-Bold", fallback: .serif),
                sizeMultiplier: 1.0
            )
        case .forest:
            // Warm, organic long-form reading.
            return ThemeTypography(
                displayName: "Georgia",
                body: .named("Georgia", fallback: .serif),
                reference: .named("Georgia-Bold", fallback: .serif),
                sizeMultiplier: 1.0
            )
        case .plainLight:
            // Pure minimal — no decorative voice.
            return ThemeTypography(
                displayName: "SF Pro",
                body: .system(design: .default, weight: .regular),
                reference: .system(design: .default, weight: .semibold),
                sizeMultiplier: 1.0
            )
        case .ink:
            // Editorial dark mode — crisp text, slightly tighter presence.
            return ThemeTypography(
                displayName: "SF Pro",
                body: .system(design: .default, weight: .regular),
                reference: .system(design: .default, weight: .bold),
                sizeMultiplier: 1.0
            )
        case .blush:
            // Soft, humanistic feminine — Optima’s flared sans.
            return ThemeTypography(
                displayName: "Optima",
                body: .named("Optima-Regular", fallback: .serif),
                reference: .named("Optima-Bold", fallback: .serif),
                sizeMultiplier: 1.02
            )
        case .lavender:
            // Literary / journal elegance.
            return ThemeTypography(
                displayName: "Hoefler Text",
                body: .named("HoeflerText-Regular", fallback: .serif),
                reference: .named("HoeflerText-Black", fallback: .serif),
                sizeMultiplier: 1.0
            )
        case .slate:
            // Geometric, industrial, no-nonsense.
            return ThemeTypography(
                displayName: "Futura",
                body: .named("Futura-Medium", fallback: .default),
                reference: .named("Futura-Bold", fallback: .default),
                sizeMultiplier: 1.0
            )
        case .navy:
            // Traditional study / leather-desk classic.
            return ThemeTypography(
                displayName: "Baskerville",
                body: .named("Baskerville", fallback: .serif),
                reference: .named("Baskerville-Bold", fallback: .serif),
                sizeMultiplier: 1.0
            )
        case .sunshine:
            // Kids: big, rounded, easy letter shapes.
            return ThemeTypography(
                displayName: "Rounded",
                body: .system(design: .rounded, weight: .medium),
                reference: .system(design: .rounded, weight: .bold),
                sizeMultiplier: 1.12
            )
        case .ocean:
            // Kids: friendly handwritten school-notebook feel.
            return ThemeTypography(
                displayName: "Noteworthy",
                body: .named("Noteworthy-Light", fallback: .rounded),
                reference: .named("Noteworthy-Bold", fallback: .rounded),
                sizeMultiplier: 1.10
            )
        }
    }

    var palette: AppThemePalette {
        switch self {
        case .system:
            return .systemAdaptive
        case .parchment:
            return AppThemePalette(
                background: Color(red: 0.96, green: 0.93, blue: 0.86),
                card: Color(red: 0.99, green: 0.97, blue: 0.92),
                primaryText: Color(red: 0.28, green: 0.22, blue: 0.16),
                secondaryText: Color(red: 0.48, green: 0.40, blue: 0.32),
                tertiaryText: Color(red: 0.62, green: 0.54, blue: 0.44),
                accent: Color(red: 0.55, green: 0.38, blue: 0.22),
                like: Color(red: 0.72, green: 0.28, blue: 0.24),
                chrome: Color(red: 0.90, green: 0.85, blue: 0.76),
                preferredColorScheme: .light
            )
        case .forest:
            return AppThemePalette(
                background: Color(red: 0.10, green: 0.16, blue: 0.12),
                card: Color(red: 0.14, green: 0.22, blue: 0.17),
                primaryText: Color(red: 0.88, green: 0.93, blue: 0.86),
                secondaryText: Color(red: 0.62, green: 0.74, blue: 0.64),
                tertiaryText: Color(red: 0.45, green: 0.56, blue: 0.48),
                accent: Color(red: 0.55, green: 0.72, blue: 0.48),
                like: Color(red: 0.85, green: 0.40, blue: 0.38),
                chrome: Color(red: 0.12, green: 0.19, blue: 0.14),
                preferredColorScheme: .dark
            )
        case .plainLight:
            return AppThemePalette(
                background: Color(red: 0.99, green: 0.99, blue: 0.99),
                card: Color(red: 1.0, green: 1.0, blue: 1.0),
                primaryText: Color(red: 0.12, green: 0.12, blue: 0.12),
                secondaryText: Color(red: 0.42, green: 0.42, blue: 0.42),
                tertiaryText: Color(red: 0.62, green: 0.62, blue: 0.62),
                accent: Color(red: 0.20, green: 0.20, blue: 0.20),
                like: Color(red: 0.85, green: 0.20, blue: 0.25),
                chrome: Color(red: 0.95, green: 0.95, blue: 0.95),
                preferredColorScheme: .light
            )
        case .ink:
            return AppThemePalette(
                background: Color(red: 0.05, green: 0.05, blue: 0.06),
                card: Color(red: 0.10, green: 0.10, blue: 0.11),
                primaryText: Color(red: 0.95, green: 0.95, blue: 0.96),
                secondaryText: Color(red: 0.70, green: 0.70, blue: 0.72),
                tertiaryText: Color(red: 0.48, green: 0.48, blue: 0.50),
                accent: Color(red: 0.92, green: 0.92, blue: 0.94),
                like: Color(red: 0.95, green: 0.30, blue: 0.35),
                chrome: Color(red: 0.08, green: 0.08, blue: 0.09),
                preferredColorScheme: .dark
            )
        case .blush:
            return AppThemePalette(
                background: Color(red: 0.99, green: 0.94, blue: 0.95),
                card: Color(red: 1.0, green: 0.98, blue: 0.98),
                primaryText: Color(red: 0.35, green: 0.20, blue: 0.26),
                secondaryText: Color(red: 0.58, green: 0.40, blue: 0.46),
                tertiaryText: Color(red: 0.72, green: 0.55, blue: 0.60),
                accent: Color(red: 0.78, green: 0.40, blue: 0.52),
                like: Color(red: 0.86, green: 0.28, blue: 0.42),
                chrome: Color(red: 0.96, green: 0.88, blue: 0.90),
                preferredColorScheme: .light
            )
        case .lavender:
            return AppThemePalette(
                background: Color(red: 0.22, green: 0.18, blue: 0.30),
                card: Color(red: 0.28, green: 0.24, blue: 0.38),
                primaryText: Color(red: 0.96, green: 0.93, blue: 1.0),
                secondaryText: Color(red: 0.78, green: 0.72, blue: 0.88),
                tertiaryText: Color(red: 0.60, green: 0.55, blue: 0.72),
                accent: Color(red: 0.78, green: 0.62, blue: 0.95),
                like: Color(red: 0.95, green: 0.45, blue: 0.60),
                chrome: Color(red: 0.18, green: 0.15, blue: 0.26),
                preferredColorScheme: .dark
            )
        case .slate:
            return AppThemePalette(
                background: Color(red: 0.14, green: 0.16, blue: 0.18),
                card: Color(red: 0.20, green: 0.22, blue: 0.25),
                primaryText: Color(red: 0.92, green: 0.93, blue: 0.94),
                secondaryText: Color(red: 0.68, green: 0.72, blue: 0.75),
                tertiaryText: Color(red: 0.48, green: 0.52, blue: 0.55),
                accent: Color(red: 0.55, green: 0.68, blue: 0.78),
                like: Color(red: 0.88, green: 0.35, blue: 0.35),
                chrome: Color(red: 0.12, green: 0.14, blue: 0.16),
                preferredColorScheme: .dark
            )
        case .navy:
            return AppThemePalette(
                background: Color(red: 0.08, green: 0.12, blue: 0.22),
                card: Color(red: 0.12, green: 0.17, blue: 0.30),
                primaryText: Color(red: 0.90, green: 0.93, blue: 0.98),
                secondaryText: Color(red: 0.62, green: 0.70, blue: 0.82),
                tertiaryText: Color(red: 0.45, green: 0.52, blue: 0.64),
                accent: Color(red: 0.40, green: 0.62, blue: 0.92),
                like: Color(red: 0.90, green: 0.35, blue: 0.40),
                chrome: Color(red: 0.06, green: 0.10, blue: 0.18),
                preferredColorScheme: .dark
            )
        case .sunshine:
            return AppThemePalette(
                background: Color(red: 1.0, green: 0.96, blue: 0.78),
                card: Color(red: 1.0, green: 0.99, blue: 0.92),
                primaryText: Color(red: 0.30, green: 0.22, blue: 0.08),
                secondaryText: Color(red: 0.55, green: 0.42, blue: 0.18),
                tertiaryText: Color(red: 0.70, green: 0.58, blue: 0.30),
                accent: Color(red: 0.95, green: 0.55, blue: 0.15),
                like: Color(red: 0.95, green: 0.25, blue: 0.35),
                chrome: Color(red: 0.98, green: 0.90, blue: 0.55),
                preferredColorScheme: .light
            )
        case .ocean:
            return AppThemePalette(
                background: Color(red: 0.78, green: 0.93, blue: 0.98),
                card: Color(red: 0.92, green: 0.98, blue: 1.0),
                primaryText: Color(red: 0.08, green: 0.28, blue: 0.40),
                secondaryText: Color(red: 0.20, green: 0.45, blue: 0.55),
                tertiaryText: Color(red: 0.35, green: 0.58, blue: 0.65),
                accent: Color(red: 0.10, green: 0.55, blue: 0.72),
                like: Color(red: 0.95, green: 0.35, blue: 0.45),
                chrome: Color(red: 0.65, green: 0.88, blue: 0.95),
                preferredColorScheme: .light
            )
        }
    }

    /// Themes grouped for the Settings picker (category → themes).
    static var grouped: [(category: String, themes: [AppThemeID])] {
        let order = ["Default", "Natural", "Minimalist", "Feminine", "Masculine", "Kids"]
        let buckets = Dictionary(grouping: allCases, by: \.category)
        return order.compactMap { cat in
            guard let themes = buckets[cat] else { return nil }
            return (cat, themes)
        }
    }
}

// MARK: - Typography

/// How a theme draws scripture and reference labels.
struct ThemeTypography: Equatable {
    var displayName: String
    var body: ThemeFontFace
    var reference: ThemeFontFace
    /// Kids themes read a bit larger by default; user size steps still apply on top.
    var sizeMultiplier: CGFloat

    func bodyFont(size: CGFloat) -> Font {
        body.font(size: size * sizeMultiplier)
    }

    func referenceFont(size: CGFloat = 12) -> Font {
        reference.font(size: size * sizeMultiplier)
    }
}

enum ThemeFontFace: Equatable {
    case system(design: Font.Design, weight: Font.Weight)
    /// PostScript name, with a system design fallback if the face is missing.
    case named(String, fallback: Font.Design)

    func font(size: CGFloat) -> Font {
        switch self {
        case .system(let design, let weight):
            return .system(size: size, weight: weight, design: design)
        case .named(let name, let fallback):
            // Font.custom still returns a font even if the name is unknown;
            // iOS substitutes a default. Prefer explicit system fallback when
            // the named face is not registered on device.
            if UIFont(name: name, size: size) != nil {
                return .custom(name, size: size)
            }
            return .system(size: size, weight: .regular, design: fallback)
        }
    }
}

struct AppThemePalette: Equatable {
    var background: Color
    var card: Color
    var primaryText: Color
    var secondaryText: Color
    var tertiaryText: Color
    var accent: Color
    var like: Color
    var chrome: Color
    /// When non-nil, force light/dark chrome around system controls.
    var preferredColorScheme: ColorScheme?

    /// Follows system semantic colors (no fixed palette).
    static let systemAdaptive = AppThemePalette(
        background: Color(.systemBackground),
        card: Color(.secondarySystemBackground),
        primaryText: Color(.label),
        secondaryText: Color(.secondaryLabel),
        tertiaryText: Color(.tertiaryLabel),
        accent: Color.accentColor,
        like: .red,
        chrome: Color(.systemBackground),
        preferredColorScheme: nil
    )
}

// MARK: - Environment

private struct AppThemePaletteKey: EnvironmentKey {
    static let defaultValue = AppThemePalette.systemAdaptive
}

private struct AppThemeTypographyKey: EnvironmentKey {
    static let defaultValue = AppThemeID.system.typography
}

extension EnvironmentValues {
    var appTheme: AppThemePalette {
        get { self[AppThemePaletteKey.self] }
        set { self[AppThemePaletteKey.self] = newValue }
    }

    var appTypography: ThemeTypography {
        get { self[AppThemeTypographyKey.self] }
        set { self[AppThemeTypographyKey.self] = newValue }
    }
}

extension View {
    func appTheme(_ palette: AppThemePalette, typography: ThemeTypography = AppThemeID.system.typography) -> some View {
        environment(\.appTheme, palette)
            .environment(\.appTypography, typography)
            .preferredColorScheme(palette.preferredColorScheme)
    }
}
