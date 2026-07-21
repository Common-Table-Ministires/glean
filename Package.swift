// swift-tools-version:5.9
import PackageDescription

/// Glean: reader shell plus the three libraries it is built from.
///
/// These live as separate *targets*, not separate repos. The boundary that
/// matters is the module boundary, and Swift enforces that at compile time:
/// the app cannot reach into selection internals, it can only `import
/// GleanSelection`. Keeping them in one repo means one clone, one CI run, and
/// one version to reason about, which is what a solo maintainer can actually
/// sustain. See docs/05-package-boundaries.md for what each target may and may
/// not depend on.
let package = Package(
    name: "Glean",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "ScriptureCore", targets: ["ScriptureCore"]),
        .library(name: "GleanSelection", targets: ["GleanSelection"]),
        .library(name: "GleanCommentary", targets: ["GleanCommentary"]),
        .executable(name: "ScripturePreview", targets: ["ScripturePreview"]),
    ],
    targets: [
        // Scripture text and storage. No selection logic, no commentary.
        .target(
            name: "ScriptureCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),

        // Formation selection brain. No UI, no SQLite, no ScriptureCore.
        .target(
            name: "GleanSelection",
            resources: [.copy("Resources/chunks.json")]
        ),

        // Open / public-domain commentary. No UI, no SQLite, no ScriptureCore.
        .target(
            name: "GleanCommentary",
            resources: [
                .copy("Resources/sources.json"),
                .copy("Resources/notes.json"),
            ]
        ),

        // macOS iteration testbed for the reader.
        .executableTarget(
            name: "ScripturePreview",
            dependencies: ["ScriptureCore", "GleanSelection"],
            resources: [
                .copy("Resources/scripture.sqlite"),
                .copy("Resources/OpenDyslexic-Regular.otf"),
            ]
        ),

        .testTarget(name: "ScriptureCoreTests", dependencies: ["ScriptureCore"]),
        .testTarget(name: "GleanSelectionTests", dependencies: ["GleanSelection"]),
        .testTarget(name: "GleanCommentaryTests", dependencies: ["GleanCommentary"]),
    ]
)
