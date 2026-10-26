import Foundation
import Observation
import PostureKit

@MainActor
@Observable
final class SetupFlow {
    enum Step: Int, CaseIterable {
        case intro, forward, back, right, left, turnRight, turnLeft, posture, done

        static let moves: [Step] = [.forward, .back, .right, .left, .turnRight, .turnLeft]

        var title: String {
            switch self {
            case .intro: "Let's learn how you move"
            case .forward: "Look down"
            case .back: "Look up"
            case .right: "Right ear to right shoulder"
            case .left: "Left ear to left shoulder"
            case .turnRight: "Turn to your right"
            case .turnLeft: "Turn to your left"
            case .posture: "Sit how you like to work"
            case .done: "All set"
            }
        }

        var instruction: String {
            switch self {
            case .intro: "Follow the head with yours. Posture learns which way is forward, back and sideways for your AirPods, then saves the way you like to sit. About a minute."
            case .forward: "Slowly bring your chin toward your chest, as far as feels comfortable."
            case .back: "Slowly tilt your head back toward the ceiling."
            case .right: "Keep looking ahead and tilt your head toward your right shoulder."
            case .left: "Keep looking ahead and tilt your head toward your left shoulder."
            case .turnRight: "Keep your chin level and turn like you're looking at a second screen."
            case .turnLeft: "Same thing, the other way."
            case .posture: "Get comfortable, look at your screen like you normally do and hold still."
            case .done: "Move your head around, this is you. Leaning back no longer counts as slouching."
            }
        }

        var target: Double {
            switch self {
            case .forward, .back: 15
            case .right, .left: 12
            case .turnRight, .turnLeft: 25
            default: 0
            }
        }

        func guide(_ amount: Double) -> HeadPose {
            switch self {
            case .forward: HeadPose(pitch: 32 * amount)
            case .back: HeadPose(pitch: -26 * amount)
            case .right: HeadPose(roll: 26 * amount)
            case .left: HeadPose(roll: -26 * amount)
            case .turnRight: HeadPose(yaw: 50 * amount)
            case .turnLeft: HeadPose(yaw: -50 * amount)
            case .intro: HeadPose(pitch: 6 * sin(amount * .pi * 2), yaw: 18 * sin(amount * .pi))
            case .posture, .done: .center
            }
        }
    }

    enum Stage: Equatable {
        case centering
        case moving
        case returning
        case countdown(Int)
        case measuring
        case idle
    }

    private struct Peak {
        let angle: Double
        let motion: Motion
        let rotation: Tilt
    }

    var step = Step.intro
    var stage = Stage.idle
    var progress = 0.0
    var message: String?
    var receiving = false
    var live = HeadPose.center
    var mobility = Mobility()
    let canSkipMoves: Bool

    @ObservationIgnored private let onFinish: (Tilt, Axes?, Mobility?) -> Void
    @ObservationIgnored private var axes: Axes?
    @ObservationIgnored private var neutral: Motion?
    @ObservationIgnored private var latest: Motion?
    @ObservationIgnored private var peak: Peak?
    @ObservationIgnored private var learned: [Step: Tilt] = [:]
    @ObservationIgnored private var samples: [Motion] = []
    @ObservationIgnored private var baseline: Tilt?
    @ObservationIgnored private var baselineAttitude: Quat?
    @ObservationIgnored private var skippedMoves = false

    init(axes: Axes?, onFinish: @escaping (Tilt, Axes?, Mobility?) -> Void) {
        self.axes = axes
        self.canSkipMoves = axes != nil
        self.onFinish = onFinish
    }

    var isMove: Bool { Step.moves.contains(step) }

    func feed(_ motion: Motion) {
        latest = motion
        if !receiving { receiving = true }
        switch step {
        case .posture where stage == .measuring: samples.append(motion)
        case .done: mirror(motion)
        default: if isMove { track(motion) }
        }
    }

    func start() {
        guard let latest else {
            message = "Waiting for your AirPods. Put both in your ears."
            return
        }
        neutral = latest
        message = nil
        begin(.forward)
    }

    func skipToPosture() {
        skippedMoves = true
        message = nil
        begin(.posture)
    }

    private func begin(_ next: Step) {
        step = next
        progress = 0
        peak = nil
        if next == .posture {
            measurePosture()
        } else {
            stage = isMove ? .centering : .idle
        }
    }

    private func track(_ motion: Motion) {
        guard let neutral else { return }
        let delta = motion.attitude.relative(to: neutral.attitude)
        let angle = delta.degrees
        switch stage {
        case .centering:
            if angle < 8 { stage = .moving }
        case .moving:
            remember(angle, motion, delta)
            progress = min(1, angle / step.target)
            if angle >= step.target {
                stage = .returning
                message = nil
            }
        case .returning:
            remember(angle, motion, delta)
            if angle < 8 { complete() }
        default:
            break
        }
    }

    private func remember(_ angle: Double, _ motion: Motion, _ delta: Quat) {
        guard angle > (peak?.angle ?? 0) else { return }
        peak = Peak(angle: angle, motion: motion, rotation: delta.rotation)
    }

    private func complete() {
        guard let neutral, let peak else { return retry(nil) }
        let tilt = Axes.between(neutral.gravity, peak.motion.gravity)
        switch step {
        case .forward:
            guard let tilt else { return retry("Not much movement there. Bring your chin toward your chest.") }
            learned[.forward] = tilt
            mobility.forward = peak.angle
        case .back:
            guard let tilt, let forward = learned[.forward], tilt.dot(forward) < -0.3 else {
                return retry("That went the same way as before. Look up toward the ceiling.")
            }
            learned[.back] = tilt
            mobility.back = peak.angle
        case .right:
            guard let tilt, let forward = learned[.forward], abs(tilt.dot(forward)) < 0.6 else {
                return retry("That looked like a nod. Keep looking ahead and tilt your ear to your shoulder.")
            }
            learned[.right] = tilt
            mobility.right = peak.angle
        case .left:
            guard let tilt, let right = learned[.right], tilt.dot(right) < -0.3 else {
                return retry("Tilt toward your other shoulder.")
            }
            learned[.left] = tilt
            mobility.left = peak.angle
        case .turnRight:
            guard neutral.gravity.degrees(from: peak.motion.gravity) < peak.angle * 0.55 else {
                return retry("Keep your chin level while you turn, like looking at a second screen.")
            }
            learned[.turnRight] = peak.rotation.normalized
            mobility.turnRight = peak.angle
        case .turnLeft:
            guard let right = learned[.turnRight], peak.rotation.normalized.dot(right) < -0.3 else {
                return retry("Turn the other way.")
            }
            learned[.turnLeft] = peak.rotation.normalized
            mobility.turnLeft = peak.angle
        default:
            break
        }
        message = nil
        begin(Step(rawValue: step.rawValue + 1) ?? .posture)
    }

    private func retry(_ hint: String?) {
        message = hint
        progress = 0
        peak = nil
        stage = .centering
    }

    private func measurePosture() {
        Task {
            for n in [3, 2, 1] {
                stage = .countdown(n)
                try? await Task.sleep(for: .seconds(1))
            }
            samples = []
            stage = .measuring
            progress = 0
            let started = Date.now
            while Date.now.timeIntervalSince(started) < Calibration.measuring {
                try? await Task.sleep(for: .milliseconds(50))
                progress = Date.now.timeIntervalSince(started) / Calibration.measuring
            }
            switch Calibration.evaluate(samples.map(\.gravity)) {
            case .ready(let tilt):
                finish(with: tilt)
            case .tooFew:
                message = "No data from your AirPods. Are both in your ears?"
                measurePosture()
            case .wobbly(let wobble):
                message = "You moved \(Int(wobble))°. Hold still for three seconds."
                measurePosture()
            }
        }
    }

    private func finish(with tilt: Tilt) {
        baseline = tilt
        baselineAttitude = samples[samples.count / 2].attitude
        if !skippedMoves,
           let forward = learned[.forward], let back = learned[.back],
           let right = learned[.right], let left = learned[.left],
           let turnRight = learned[.turnRight], let turnLeft = learned[.turnLeft] {
            axes = Axes.learn(forward: forward, back: back, right: right, left: left, turnRight: turnRight, turnLeft: turnLeft)
            onFinish(tilt, axes, mobility)
        } else {
            onFinish(tilt, nil, nil)
        }
        message = nil
        stage = .idle
        step = .done
    }

    private func mirror(_ motion: Motion) {
        guard let baseline else { return }
        let lean = Lean(tilt: motion.gravity, baseline: baseline, axes: axes)
        var yaw = 0.0
        if let axes, let baselineAttitude {
            yaw = motion.attitude.relative(to: baselineAttitude).rotation.dot(axes.yaw) * 180 / .pi
        }
        live = HeadPose(pitch: lean.pitch, roll: lean.roll, yaw: yaw)
    }
}
