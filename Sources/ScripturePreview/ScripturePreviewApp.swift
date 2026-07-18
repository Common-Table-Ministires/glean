import SwiftUI
import CoreText

@main
struct ScripturePreviewApp: App {
    init() {
        Self.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .windowResizability(.contentSize)
    }

    private static func registerBundledFonts() {
        guard let url = Bundle.module.url(forResource: "OpenDyslexic-Regular", withExtension: "otf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
