// swift-tools-version:5.9
import PackageDescription

/// Glean reader shell + ScriptureCore.
/// Selection brain is a *separate* package (GleanSelection / Desktop biblealgo).
/// Do not copy algorithm sources into this package — depend on GleanSelection only.
let package = Package(
    name: "ScriptureApp",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "ScriptureCore", targets: ["ScriptureCore"]),
        .executable(name: "ScripturePreview", targets: ["ScripturePreview"]),
    ],
    dependencies: [
        // Integrity: single source of truth for formation selection.
        // Relative path from sarah/glean → Desktop/biblealgo on this machine.
        .package(path: "../../Desktop/biblealgo"),
    ],
    targets: [
        .target(
            name: "ScriptureCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .executableTarget(
            name: "ScripturePreview",
            dependencies: [
                "ScriptureCore",
                .product(name: "GleanSelection", package: "biblealgo"),
            ],
            resources: [
                .copy("Resources/scripture.sqlite"),
                .copy("Resources/OpenDyslexic-Regular.otf"),
            ]
        ),
        .testTarget(
            name: "ScriptureCoreTests",
            dependencies: ["ScriptureCore"]
        ),
    ]
)
