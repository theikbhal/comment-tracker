// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommentTracker",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "CommentTracker",
            path: "Sources/CommentTracker",
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
