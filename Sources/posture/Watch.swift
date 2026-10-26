import Foundation

struct WatchOptions {
    var threshold: Double
    var grace: Double
    var json = false
    var quiet = false
}

@MainActor
final class Watch {
    private let options: WatchOptions
    private let baseline: Tilt
    private let session: Session
    private var smoothed: Tilt?
    private var lastSample: Date?
    private var slouchStart: Date?
    private var lastAlert: Date?
    private var lastEmit = Date.distantPast
    private var lastFlush = Date.now
    private var dayKey = Store.todayKey()
    private var day: Day
    private var sessionWatched = 0.0
    private var sessionSlouched = 0.0
    private var connected = true
    private var signals: [DispatchSourceSignal] = []

    init(baseline: Tilt, options: WatchOptions, session: Session = Session()) {
        self.session = session
        self.baseline = baseline
        self.options = options
        self.day = Store.history()[dayKey] ?? Day()
    }

    func start() {
        trapExit()
        if !options.json {
            Format.line(Format.dim("Watching your posture. Threshold \(Int(options.threshold))°, nudge after \(Format.duration(options.grace)). Ctrl-C to stop."))
        }
        session.listen { [self] event in
            switch event {
            case .tilt(let tilt): handle(tilt)
            case .connected: connected = true
            case .disconnected:
                connected = false
                lastSample = nil
                slouchStart = nil
                if options.json { emit(["event": "disconnected"]) } else { Format.status(Format.dim("AirPods disconnected, waiting…")) }
            }
        }
    }

    private func handle(_ tilt: Tilt) {
        let now = Date.now
        let current = smoothed?.blended(toward: tilt, by: 0.15) ?? tilt
        smoothed = current
        let degrees = current.degrees(from: baseline)
        let slouching = degrees >= options.threshold
        let dt = lastSample.map { min(1, now.timeIntervalSince($0)) } ?? 0
        lastSample = now

        rollDayIfNeeded(now)
        day.watched += dt
        sessionWatched += dt
        if slouching {
            day.slouched += dt
            sessionSlouched += dt
        }

        if slouching {
            let start = slouchStart ?? now
            slouchStart = start
            let held = now.timeIntervalSince(start)
            let due = lastAlert.map { now.timeIntervalSince($0) >= max(60, options.grace * 3) } ?? true
            if held >= options.grace && due {
                lastAlert = now
                day.alerts += 1
                Nudge.slouching(for: held, quiet: options.quiet)
                if options.json { emit(["event": "nudge", "degrees": round(degrees), "seconds": round(held)]) }
            }
        } else {
            if lastAlert != nil, slouchStart != nil { Nudge.recovered(quiet: options.quiet) }
            slouchStart = nil
            lastAlert = nil
        }

        render(degrees: degrees, slouching: slouching, now: now)
        if now.timeIntervalSince(lastFlush) >= 30 { flush() }
    }

    private func render(degrees: Double, slouching: Bool, now: Date) {
        guard now.timeIntervalSince(lastEmit) >= (options.json ? 1 : 0.1) else { return }
        lastEmit = now
        if options.json {
            emit(["event": "sample", "degrees": round(degrees), "slouching": slouching])
            return
        }
        let held = slouchStart.map { now.timeIntervalSince($0) } ?? 0
        let state = slouching ? Format.red("slouching \(Format.duration(held))") : Format.green("upright")
        let angle = String(format: "%3.0f°", degrees)
        let score = Day(watched: sessionWatched, slouched: sessionSlouched).score
        Format.status("\(Format.meter(degrees, threshold: options.threshold)) \(angle)  \(state)  \(Format.dim("· score \(score) · \(Format.duration(sessionWatched))"))")
    }

    private func rollDayIfNeeded(_ now: Date) {
        let key = Store.todayKey(now)
        guard key != dayKey else { return }
        flush()
        dayKey = key
        day = Store.history()[key] ?? Day()
    }

    private func flush() {
        Store.record(day, on: dayKey)
        lastFlush = .now
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
        flush()
        let summary = Day(watched: sessionWatched, slouched: sessionSlouched)
        if options.json {
            emit(["event": "summary", "watched": round(sessionWatched), "slouched": round(sessionSlouched), "score": summary.score])
        } else {
            Format.status("")
            Format.line("Session \(Format.duration(sessionWatched)), slouched \(Format.duration(sessionSlouched)), score \(Format.bold("\(summary.score)")).")
        }
        exit(0)
    }
}
