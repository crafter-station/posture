import AppKit
import Foundation
import PostureKit

struct WatchOptions {
    var threshold: Double
    var grace: Double
    var repeatEvery: Double
    var json = false
    var quiet = false
}

@MainActor
final class Watch {
    static let menuBarApp = "run.crafter.posture.bar"

    private let options: WatchOptions
    private let session: Session
    private let tracker: Tracker
    private var lastRender = Date.distantPast
    private var signals: [DispatchSourceSignal] = []

    init(baseline: Tilt, options: WatchOptions, session: Session = Session()) {
        self.options = options
        self.session = session
        let appTracking = !NSRunningApplication.runningApplications(withBundleIdentifier: Self.menuBarApp).isEmpty
        tracker = Tracker(baseline: baseline, axes: Store.settings().axes, threshold: options.threshold, grace: options.grace, repeatEvery: options.repeatEvery, record: !appTracking)
        if appTracking, !options.json {
            Format.line(Format.dim("The menu bar app is already recording, so this session is view only."))
        }
    }

    func start() {
        trapExit()
        if !options.json {
            Format.line(Format.dim("Watching your posture. Threshold \(Int(options.threshold))°, nudge after \(Format.duration(options.grace)), \(options.repeatEvery > 0 ? "repeat every \(Format.duration(options.repeatEvery))" : "once"). Ctrl-C to stop."))
        }
        session.listen { [self] event in
            switch event {
            case .motion(let motion): handle(tracker.feed(motion.gravity))
            case .connected: break
            case .disconnected:
                tracker.interrupt()
                if options.json { emit(["event": "disconnected"]) } else { Format.status(Format.dim("AirPods disconnected, waiting…")) }
            }
        }
    }

    private func handle(_ reading: Tracker.Reading) {
        switch reading.event {
        case .nudge(let seconds):
            Nudge.slouching(for: seconds, quiet: options.quiet)
            if options.json { emit(["event": "nudge", "degrees": reading.degrees.rounded(), "seconds": seconds.rounded()]) }
        case .recovered:
            Nudge.recovered(quiet: options.quiet)
        case nil:
            break
        }
        render(reading)
    }

    private func render(_ reading: Tracker.Reading) {
        let now = Date.now
        guard now.timeIntervalSince(lastRender) >= (options.json ? 1 : 0.1) else { return }
        lastRender = now
        if options.json {
            emit(["event": "sample", "degrees": reading.degrees.rounded(), "pitch": reading.lean.pitch.rounded(), "roll": reading.lean.roll.rounded(), "direction": reading.lean.direction, "slouching": reading.slouching, "streak": reading.streak.rounded()])
            return
        }
        let state = reading.slouching ? Format.red("slouching \(Format.duration(reading.held))") : Format.green("upright")
        let angle = String(format: "%3.0f° %@", reading.degrees, reading.lean.directional ? reading.lean.direction.padding(toLength: 7, withPad: " ", startingAt: 0) : "")
        let detail = "· score \(tracker.session.score) · streak \(Format.duration(reading.streak)) · \(Format.duration(tracker.session.watched))"
        Format.status("\(Format.meter(reading.degrees, threshold: options.threshold)) \(angle)  \(state)  \(Format.dim(detail))")
    }

    private func emit(_ object: [String: Any]) {
        var payload = object
        payload["at"] = Date.now.formatted(.iso8601)
        Format.line(Format.json(payload))
    }

    private func trapExit() {
        for code in [SIGINT, SIGTERM] {
            signal(code, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: code, queue: .main)
            source.setEventHandler { [self] in finish() }
            source.resume()
            signals.append(source)
        }
    }

    private func finish() {
        tracker.flush()
        let session = tracker.session
        if options.json {
            emit(["event": "summary", "watched": session.watched.rounded(), "slouched": session.slouched.rounded(), "score": session.score, "bestStreak": session.bestStreak.rounded()])
        } else {
            Format.status("")
            Format.line("Session \(Format.duration(session.watched)), slouched \(Format.duration(session.slouched)), best streak \(Format.duration(session.bestStreak)), score \(Format.bold("\(session.score)")).")
        }
        exit(0)
    }
}
