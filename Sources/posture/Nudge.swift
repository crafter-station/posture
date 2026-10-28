import Foundation
import PostureKit

enum Nudge {
    static func slouching(for seconds: Double, sound: String?) {
        notify(title: "Sit up straight", body: "You've been slouching for \(Format.duration(seconds)).")
        if let sound { play(sound) }
    }

    static func recovered(sound: String?) {
        if let sound { play(sound) }
    }

    private static func notify(title: String, body: String) {
        run("/usr/bin/osascript", ["-e", "display notification \"\(body)\" with title \"\(title)\""])
    }

    private static func play(_ sound: String) {
        guard !sound.isEmpty else { return }
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
