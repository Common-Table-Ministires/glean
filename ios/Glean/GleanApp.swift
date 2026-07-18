import SwiftUI
import CoreText

@main
struct GleanApp: App {
    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }

    private static func registerBundledFonts() {
        guard let url = Bundle.main.url(forResource: "OpenDyslexic-Regular", withExtension: "otf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
