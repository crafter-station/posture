import Foundation
import PostureKit

@MainActor
enum Calibrate {
    private static var retries = 0

    static func run(session: Session = Session(), then next: ((Session) -> Void)? = nil) {
        Format.line(Format.bold("Sit up straight") + " and look at your screen like you normally would.")
        session.listen { _ in }
        countdown(from: 3) {
            Format.status(Format.dim("Hold still, measuring…"))
            session.collect(for: Calibration.measuring) { samples in
                switch Calibration.evaluate(samples) {
                case .ready(let baseline):
                    var settings = Store.settings()
                    settings.baseline = baseline
                    Store.save(settings)
                    Format.status("")
                    Format.line(Format.green("✓") + " Calibrated. This is your upright posture.")
                    if let next { next(session) } else { exit(0) }
                case .tooFew:
                    Format.status(Format.dim("Waiting for your AirPods…"))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { again(session, next) }
                case .wobbly(let wobble):
                    Format.status("")
                    Format.line(Format.yellow("You moved too much (\(Int(wobble))°). Try again."))
                    again(session, next)
                }
            }
        }
    }

    private static func again(_ session: Session, _ next: ((Session) -> Void)?) {
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
