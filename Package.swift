// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ScriptureApp",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ScriptureCore", targets: ["ScriptureCore"]),
        .executable(name: "ScripturePreview", targets: ["ScripturePreview"]),
    ],
    targets: [
        .target(
            name: "ScriptureCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .executableTarget(
            name: "ScripturePreview",
            dependencies: ["ScriptureCore"],
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
