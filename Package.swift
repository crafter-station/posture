// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "posture",
    platforms: [.macOS(.v15)],
    targets: [
        .target(
            name: "PostureKit",
            linkerSettings: [.linkedFramework("CoreMotion")]
        ),
        .executableTarget(
            name: "posture",
            dependencies: ["PostureKit"],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Info.plist"])
            ]
        ),
        .executableTarget(
            name: "PostureBar",
            dependencies: ["PostureKit"]
        )
    ]
)
