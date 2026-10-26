import AppKit
import Foundation
import PostureKit

@MainActor
enum Commands {
    static func now(json: Bool) {
        let settings = Store.settings()
        guard let baseline = settings.baseline else { fail(NotCalibrated()) }
        Session().collect(for: 1.5) { samples in
            guard let tilt = Tilt.mean(samples) else { fail(SensorError.silent) }
            let lean = Lean(tilt: tilt, baseline: baseline, axes: settings.axes)
            let slouching = lean.slouching(threshold: settings.threshold)
            if json {
                Format.line(Format.json(["degrees": lean.drop.rounded(), "pitch": lean.pitch.rounded(), "roll": lean.roll.rounded(), "direction": lean.direction, "slouching": slouching, "threshold": settings.threshold]))
            } else {
                let state = slouching ? Format.red("slouching") : Format.green("upright")
                let detail = lean.directional ? String(format: "%.0f° forward · %.0f° %@", lean.pitch, abs(lean.roll), lean.roll >= 0 ? "right" : "left") : String(format: "%.0f°", lean.total)
                Format.line("\(Format.meter(lean.drop, threshold: settings.threshold)) \(detail)  \(state)")
            }
            exit(slouching ? 1 : 0)
        }
    }

    static func stats(json: Bool, days: Int) {
        let history = Store.history()
        let keys = Store.recentKeys(days)
        if json {
            let rows = keys.map { key -> [String: Any] in
                let day = history[key] ?? Day()
                let hours = day.hourly.map { ["hour": $0.hour, "watched": $0.slot.watched.rounded(), "slouched": $0.slot.slouched.rounded()] }
                return ["date": key, "watched": day.watched.rounded(), "slouched": day.slouched.rounded(), "alerts": day.alerts, "score": day.score, "bestStreak": day.bestStreak.rounded(), "hours": hours]
            }
            Format.line(Format.json(["days": rows]))
            exit(0)
        }
        Format.line(Format.dim("date         watched    slouched   streak     nudges  score"))
        for key in keys {
            guard let day = history[key], day.watched > 0 else {
                Format.line(Format.dim("\(key)   –"))
                continue
            }
            Format.line("\(key)   \(pad(Format.duration(day.watched)))\(pad(Format.duration(day.slouched)))\(pad(Format.duration(day.bestStreak)))\(pad("\(day.alerts)", 8))\(tinted(day.score))")
        }
        let hours = history[Store.dayKey()]?.hourly.filter { $0.slot.watched >= 30 } ?? []
        if !hours.isEmpty {
            Format.line("")
            Format.line(Format.dim("today by hour"))
            for (hour, slot) in hours {
                let percent = Int((slot.upright * 100).rounded())
                Format.line("  \(String(format: "%02d", hour)):00  \(Format.meter(100 - Double(percent), threshold: 30, width: 16))  \(tinted(percent))% upright")
            }
        }
        exit(0)
    }

    static func open() {
        let candidates = ["/Applications/Posture.app", NSHomeDirectory() + "/Applications/Posture.app"]
        guard let app = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            fail(NotInstalled())
        }
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: app), configuration: .init()) { _, error in
            if let error { fail(error) }
            exit(0)
        }
    }

    private static func tinted(_ score: Int) -> String {
        score >= 80 ? Format.green("\(score)") : score >= 60 ? Format.yellow("\(score)") : Format.red("\(score)")
    }

    static func config(threshold: Double?, grace: Double?, json: Bool) {
        var settings = Store.settings()
        if let threshold { settings.threshold = threshold }
        if let grace { settings.grace = grace }
        if threshold != nil || grace != nil { Store.save(settings) }
        if json {
            Format.line(Format.json(["threshold": settings.threshold, "grace": settings.grace, "calibrated": settings.baseline != nil, "path": Store.directory.path]))
        } else {
            Format.line("threshold   \(Int(settings.threshold))°")
            Format.line("grace       \(Format.duration(settings.grace))")
            Format.line("calibrated  \(settings.baseline != nil ? "yes" : "no")")
            Format.line("direction   \(settings.axes != nil ? "learned" : "not learned")")
            if let m = settings.mobility {
                Format.line("mobility    forward \(Int(m.forward))° · back \(Int(m.back))° · tilt \(Int(m.left))°/\(Int(m.right))° · turn \(Int(m.turnLeft))°/\(Int(m.turnRight))°")
            }
            Format.line(Format.dim("stored in \(Store.directory.path)"))
        }
        exit(0)
    }

    private static func pad(_ text: String, _ width: Int = 11) -> String {
        text.padding(toLength: max(width, text.count + 1), withPad: " ", startingAt: 0)
    }
}

struct NotInstalled: Error, CustomStringConvertible {
    var description: String { "Posture.app is not installed. Run `scripts/bundle.sh` in the posture repo." }
}

struct NotCalibrated: Error, CustomStringConvertible {
    var description: String { "Not calibrated yet. Run `posture calibrate` first." }
}

@MainActor
enum Doctor {
    static func run(json: Bool) {
        let sensor = HeadSensor()
        let access = HeadSensor.access
        let settings = Store.settings()
        let session = Session()
        session.tolerant = true
        session.collect(for: 3) { samples in
            let report: [(String, String, Bool)] = [
                ("motion headphones", sensor.isAvailable ? "supported" : "none found", sensor.isAvailable),
                ("motion access", access, access == "granted"),
                ("sensor data", samples.isEmpty ? "silent" : "\(samples.count) samples in 3s", !samples.isEmpty),
                ("calibrated", settings.baseline != nil ? "yes" : "no", settings.baseline != nil),
                ("direction", settings.axes != nil ? "learned" : "not yet, run setup in the menu bar app", settings.axes != nil),
            ]
            if json {
                Format.line(Format.json(Dictionary(uniqueKeysWithValues: report.map { ($0.0, $0.1) })))
            } else {
                for (name, value, ok) in report {
                    Format.line("\(ok ? Format.green("✓") : Format.red("✗")) \(name.padding(toLength: 18, withPad: " ", startingAt: 0))\(value)")
                }
            }
            exit(report.allSatisfy(\.2) ? 0 : 1)
        }
    }
}
