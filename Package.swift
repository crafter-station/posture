// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "posture",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "posture",
            linkerSettings: [
                .linkedFramework("CoreMotion"),
                .unsafeFlags(["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "Info.plist"])
            ]
        )
    ]
)
