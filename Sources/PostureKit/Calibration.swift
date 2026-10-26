import Foundation

public enum Calibration {
    public enum Outcome: Sendable {
        case ready(Tilt)
        case tooFew
        case wobbly(Double)
    }

    public static let measuring = 3.0

    public static func evaluate(_ collected: [Tilt]) -> Outcome {
        let samples = Array(collected.dropFirst(collected.count / 6))
        guard samples.count >= 5, let baseline = Tilt.mean(samples) else { return .tooFew }
        let deviations = samples.map { $0.degrees(from: baseline) }.sorted()
        let wobble = deviations[deviations.count * 9 / 10]
        return wobble < 8 ? .ready(baseline) : .wobbly(wobble)
    }
}
