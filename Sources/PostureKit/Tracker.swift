import Foundation

@MainActor
public final class Tracker {
    public enum Event: Sendable {
        case nudge(seconds: Double)
        case recovered
    }

    public struct Reading: Sendable {
        public let lean: Lean
        public let degrees: Double
        public let slouching: Bool
        public let held: Double
        public let streak: Double
        public let event: Event?
    }

    public var baseline: Tilt
    public var axes: Axes?
    public var threshold: Double
    public var grace: Double
    public var repeatEvery: Double
    public private(set) var day: Day
    public private(set) var session = Day()

    private let record: Bool
    private var dayKey: String
    private var smoothed: Tilt?
    private var lastSample: Date?
    private var slouchStart: Date?
    private var streakStart: Date?
    private var lastNudge: Date?
    private var lastFlush = Date.now

    public init(baseline: Tilt, axes: Axes?, threshold: Double, grace: Double, repeatEvery: Double, record: Bool = true) {
        self.baseline = baseline
        self.axes = axes
        self.threshold = threshold
        self.grace = grace
        self.repeatEvery = repeatEvery
        self.record = record
        dayKey = Store.dayKey()
        day = Store.history()[dayKey] ?? Day()
    }

    public func feed(_ tilt: Tilt, at now: Date = .now) -> Reading {
        let current = smoothed?.blended(toward: tilt, by: 0.15) ?? tilt
        smoothed = current
        let lean = Lean(tilt: current, baseline: baseline, axes: axes)
        let degrees = lean.drop
        let slouching = lean.slouching(threshold: threshold)
        let elapsed = lastSample.map { min(1, now.timeIntervalSince($0)) } ?? 0
        lastSample = now

        rollDay(now)
        day.add(elapsed, slouching: slouching, at: now)
        session.add(elapsed, slouching: slouching, at: now)
        let streakFrom = streakStart ?? now
        streakStart = streakFrom

        var event: Event?
        var held = 0.0
        if slouching {
            let start = slouchStart ?? now
            slouchStart = start
            held = now.timeIntervalSince(start)
            if held >= grace {
                streakStart = now
                let due = lastNudge.map { repeatEvery > 0 && now.timeIntervalSince($0) >= repeatEvery } ?? true
                if due {
                    lastNudge = now
                    day.alerts += 1
                    session.alerts += 1
                    event = .nudge(seconds: held)
                }
            }
        } else {
            if lastNudge != nil { event = .recovered }
            slouchStart = nil
            lastNudge = nil
        }

        let streak = now.timeIntervalSince(streakStart ?? now)
        day.bestStreak = max(day.bestStreak, streak)
        session.bestStreak = max(session.bestStreak, streak)
        if now.timeIntervalSince(lastFlush) >= 30 { flush() }
        return Reading(lean: lean, degrees: degrees, slouching: slouching, held: held, streak: streak, event: event)
    }

    public func interrupt() {
        smoothed = nil
        lastSample = nil
        slouchStart = nil
        streakStart = nil
        lastNudge = nil
    }

    public func flush() {
        lastFlush = .now
        guard record else { return }
        Store.record(day, on: dayKey)
    }

    private func rollDay(_ now: Date) {
        let key = Store.dayKey(now)
        guard key != dayKey else { return }
        flush()
        dayKey = key
        day = Store.history()[key] ?? Day()
    }
}
