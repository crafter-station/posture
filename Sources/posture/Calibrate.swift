import Foundation

@MainActor
enum Calibrate {
    static func run(session: Session = Session(), then next: ((Session) -> Void)? = nil) {
        Format.line(Format.bold("Sit up straight") + " and look at your screen like you normally would.")
        session.listen { _ in }
        countdown(from: 3) {
            Format.status(Format.dim("Hold still, measuring…"))
            session.collect(for: 3) { collected in
                let samples = Array(collected.dropFirst(collected.count / 6))
                guard samples.count >= 5, let baseline = Tilt.mean(samples) else {
                    Format.status(Format.dim("Waiting for your AirPods…"))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { measureAgain(session, next) }
                    return
                }
                let deviations = samples.map { $0.degrees(from: baseline) }.sorted()
                let wobble = deviations[deviations.count * 9 / 10]
                guard wobble < 8 else {
                    Format.status("")
                    Format.line(Format.yellow("You moved too much (\(Int(wobble))°). Try again."))
                    measureAgain(session, next)
                    return
                }
                var settings = Store.settings()
                settings.baseline = baseline
                Store.save(settings)
                Format.status("")
                Format.line(Format.green("✓") + " Calibrated. This is your upright posture.")
                if let next { next(session) } else { exit(0) }
            }
        }
    }

    private static var retries = 0

    private static func measureAgain(_ session: Session, _ next: ((Session) -> Void)?) {
        retries += 1
        guard retries < 4 else { fail(SensorError.silent) }
        Format.status("")
        run(session: session, then: next)
    }

    private static func countdown(from n: Int, then done: @escaping () -> Void) {
        guard n > 0 else { return done() }
        Format.status(Format.dim("Starting in \(n)…"))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { countdown(from: n - 1, then: done) }
    }
}
