import Foundation

enum Nudge {
    static func slouching(for seconds: Double, quiet: Bool) {
        notify(title: "Sit up straight", body: "You've been slouching for \(Format.duration(seconds)).")
        if !quiet { play("Funk") }
    }

    static func recovered(quiet: Bool) {
        if !quiet { play("Tink") }
    }

    private static func notify(title: String, body: String) {
        run("/usr/bin/osascript", ["-e", "display notification \"\(body)\" with title \"\(title)\""])
    }

    private static func play(_ sound: String) {
        run("/usr/bin/afplay", ["/System/Library/Sounds/\(sound).aiff"])
    }

    private static func run(_ path: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
    }
}
