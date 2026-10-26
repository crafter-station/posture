import AppKit
import Observation
import PostureKit
import ServiceManagement

struct DayRow: Identifiable {
    let key: String
    let label: String
    let day: Day
    let isToday: Bool

    var id: String { key }
}

@MainActor
@Observable
final class Monitor {
    enum Phase: Equatable {
        case starting
        case live
        case waiting
        case paused
        case uncalibrated
        case countdown(Int)
        case measuring
        case problem(String)
    }

    var phase = Phase.starting
    var degrees = 0
    var slouching = false
    var held = 0.0
    var streak = 0.0
    var today = Day()
    var week: [DayRow] = []
    var note: String?
    var settings = Store.settings()
    var opensAtLogin = SMAppService.mainApp.status == .enabled

    @ObservationIgnored private let sensor = HeadSensor()
    @ObservationIgnored private var tracker: Tracker?
    @ObservationIgnored private var samples: [Tilt] = []
    @ObservationIgnored private var lastHeard: Date?
    @ObservationIgnored private var lastPublish = Date.distantPast
    @ObservationIgnored private var timers: [Timer] = []

    init() {
        Notifier.shared.prepare()
        tracker = settings.baseline.map { Tracker(baseline: $0, threshold: settings.threshold, grace: settings.grace) }
        today = tracker?.day ?? Store.history()[Store.dayKey()] ?? Day()
        refreshWeek()
        listen()
        every(2) { $0.watchdog() }
        every(60) { $0.sync() }
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tracker?.flush() }
        }
    }

    var icon: NSImage {
        let tone: Glyph.Tone = switch phase {
        case .live: slouching ? .alert : .calm
        case .countdown, .measuring: .calm
        default: .idle
        }
        let label = settings.showAngle && phase == .live ? "\(degrees)°" : nil
        return Glyph.image(degrees: phase == .live ? Double(degrees) : 0, tone: tone, label: label)
    }

    var headline: String {
        switch phase {
        case .starting: "Starting…"
        case .live: slouching ? "Slouching \(Duration.text(held))" : "Upright"
        case .waiting: "Waiting for AirPods"
        case .paused: "Paused"
        case .uncalibrated: "Calibrate to start"
        case .countdown(let n): "Sit up straight… \(n)"
        case .measuring: "Hold still…"
        case .problem: "Can't read your AirPods"
        }
    }

    var detail: String {
        switch phase {
        case .live: "\(degrees)° from upright · streak \(Duration.text(streak))"
        case .waiting: "Put both AirPods in your ears"
        case .paused: "Not tracking right now"
        case .uncalibrated: "Sit the way you want to sit, then calibrate"
        case .countdown, .measuring: "Look at your screen like you normally do"
        case .problem(let message): message
        case .starting: ""
        }
    }

    func calibrate() {
        if phase == .paused { listen() }
        note = nil
        Task {
            for n in [3, 2, 1] {
                phase = .countdown(n)
                try? await Task.sleep(for: .seconds(1))
            }
            samples = []
            phase = .measuring
            try? await Task.sleep(for: .seconds(Calibration.measuring))
            switch Calibration.evaluate(samples) {
            case .ready(let baseline):
                update { $0.baseline = baseline }
                tracker?.flush()
                tracker = Tracker(baseline: baseline, threshold: settings.threshold, grace: settings.grace)
                note = "Calibrated. That's your upright."
                phase = .waiting
            case .tooFew:
                note = "No data from your AirPods. Are they in your ears?"
                phase = tracker == nil ? .uncalibrated : .waiting
            case .wobbly(let wobble):
                note = "You moved \(Int(wobble))°. Hold still and try again."
                phase = tracker == nil ? .uncalibrated : .waiting
            }
        }
    }

    func togglePause() {
        if phase == .paused {
            listen()
        } else {
            sensor.stop()
            tracker?.flush()
            tracker?.interrupt()
            phase = .paused
        }
    }

    func update(_ change: (inout Settings) -> Void) {
        change(&settings)
        Store.save(settings)
        tracker?.threshold = settings.threshold
        tracker?.grace = settings.grace
    }

    func setOpensAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            note = "Couldn't change login item: \(error.localizedDescription)"
        }
        opensAtLogin = SMAppService.mainApp.status == .enabled
    }

    func sync() {
        tracker?.flush()
        let stored = Store.settings()
        if let baseline = stored.baseline, baseline != settings.baseline {
            settings.baseline = baseline
            tracker?.baseline = baseline
        }
        if let tracker { today = tracker.day }
        refreshWeek()
    }

    private func listen() {
        do {
            try sensor.start { [weak self] event in self?.handle(event) }
            phase = tracker == nil ? .uncalibrated : .waiting
        } catch {
            phase = .problem("\(error)")
        }
    }

    private func handle(_ event: SensorEvent) {
        switch event {
        case .tilt(let tilt):
            lastHeard = .now
            switch phase {
            case .measuring: samples.append(tilt)
            case .countdown, .paused, .uncalibrated, .problem: break
            case .starting, .waiting, .live:
                guard let tracker else { return }
                if phase != .live { phase = .live }
                publish(tracker.feed(tilt))
            }
        case .connected:
            break
        case .disconnected:
            goIdle()
        }
    }

    private func publish(_ reading: Tracker.Reading) {
        switch reading.event {
        case .nudge(let seconds): Notifier.shared.nudge(after: seconds, sound: settings.sound)
        case .recovered: Notifier.shared.recovered(sound: settings.sound)
        case nil: break
        }
        let rounded = Int(reading.degrees.rounded())
        if rounded != degrees { degrees = rounded }
        if reading.slouching != slouching { slouching = reading.slouching }
        guard Date.now.timeIntervalSince(lastPublish) >= 1 else { return }
        lastPublish = .now
        held = reading.held
        streak = reading.streak
        if let tracker { today = tracker.day }
    }

    private func watchdog() {
        guard phase == .live, let lastHeard, Date.now.timeIntervalSince(lastHeard) > 3 else { return }
        goIdle()
    }

    private func goIdle() {
        guard phase == .live else { return }
        tracker?.interrupt()
        tracker?.flush()
        slouching = false
        phase = .waiting
    }

    private func refreshWeek() {
        let history = Store.history()
        let todayKey = Store.dayKey()
        week = (0..<7).reversed().compactMap { offset in
            guard let date = Calendar.current.date(byAdding: .day, value: -offset, to: .now) else { return nil }
            let key = Store.dayKey(date)
            let day = key == todayKey ? today : history[key] ?? Day()
            return DayRow(key: key, label: date.formatted(.dateTime.weekday(.narrow)), day: day, isToday: key == todayKey)
        }
    }

    private func every(_ seconds: Double, _ action: @escaping @MainActor @Sendable (Monitor) -> Void) {
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { if let self { action(self) } }
        }
        timers.append(timer)
    }
}
