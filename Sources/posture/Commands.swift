import CoreMotion
import Foundation

@MainActor
enum Commands {
    static func now(json: Bool) {
        let settings = Store.settings()
        guard let baseline = settings.baseline else { fail(NotCalibrated()) }
        Session().collect(for: 1.5) { samples in
            guard let tilt = Tilt.mean(samples) else { fail(SensorError.silent) }
            let degrees = tilt.degrees(from: baseline)
            let slouching = degrees >= settings.threshold
            if json {
                Format.line(Format.json(["degrees": round(degrees), "slouching": slouching, "threshold": settings.threshold]))
            } else {
                let state = slouching ? Format.red("slouching") : Format.green("upright")
                Format.line("\(Format.meter(degrees, threshold: settings.threshold)) \(Int(degrees.rounded()))°  \(state)")
            }
            exit(slouching ? 1 : 0)
        }
    }

    static func stats(json: Bool, days: Int) {
        let history = Store.history()
        let keys = (0..<days).reversed().map { Store.todayKey(Calendar.current.date(byAdding: .day, value: -$0, to: .now)!) }
        if json {
            let rows = keys.map { key -> [String: Any] in
                let day = history[key] ?? Day()
                return ["date": key, "watched": round(day.watched), "slouched": round(day.slouched), "alerts": day.alerts, "score": day.score]
            }
            Format.line(Format.json(["days": rows]))
            return
        }
        Format.line(Format.dim("date         watched    slouched   nudges  score"))
        for key in keys {
            guard let day = history[key], day.watched > 0 else {
                Format.line(Format.dim("\(key)   –"))
                continue
            }
            let score = day.score >= 80 ? Format.green("\(day.score)") : day.score >= 60 ? Format.yellow("\(day.score)") : Format.red("\(day.score)")
            Format.line("\(key)   \(pad(Format.duration(day.watched)))\(pad(Format.duration(day.slouched)))\(pad("\(day.alerts)", 8))\(score)")
        }
        exit(0)
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
            Format.line(Format.dim("stored in \(Store.directory.path)"))
        }
        exit(0)
    }

    private static func pad(_ text: String, _ width: Int = 11) -> String {
        text.padding(toLength: max(width, text.count + 1), withPad: " ", startingAt: 0)
    }
}

struct NotCalibrated: Error, CustomStringConvertible {
    var description: String { "Not calibrated yet. Run `posture calibrate` first." }
}

@MainActor
enum Doctor {
    static func run(json: Bool) {
        let manager = CMHeadphoneMotionManager()
        let access = switch CMHeadphoneMotionManager.authorizationStatus() {
        case .authorized: "granted"
        case .denied: "denied"
        case .restricted: "restricted"
        default: "not asked yet"
        }
        let settings = Store.settings()
        let session = Session()
        session.tolerant = true
        session.collect(for: 3) { samples in
            let report: [(String, String, Bool)] = [
                ("motion headphones", manager.isDeviceMotionAvailable ? "supported" : "none found", manager.isDeviceMotionAvailable),
                ("motion access", access, access == "granted"),
                ("sensor data", samples.isEmpty ? "silent" : "\(samples.count) samples in 3s", !samples.isEmpty),
                ("calibrated", settings.baseline != nil ? "yes" : "no", settings.baseline != nil),
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
