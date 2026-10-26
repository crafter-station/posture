import Foundation

public struct Axes: Codable, Equatable, Sendable {
    public var pitch: Tilt
    public var roll: Tilt
    public var yaw: Tilt

    public init(pitch: Tilt, roll: Tilt, yaw: Tilt) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
    }

    public static func learn(forward: Tilt, back: Tilt, right: Tilt, left: Tilt, turnRight: Tilt, turnLeft: Tilt) -> Axes {
        let pitch = (forward - back).normalized
        let side = (right - left).normalized
        let roll = (side - pitch * side.dot(pitch)).normalized
        return Axes(pitch: pitch, roll: roll, yaw: (turnRight - turnLeft).normalized)
    }

    public static func between(_ from: Tilt, _ to: Tilt) -> Tilt? {
        let c = from.normalized.cross(to.normalized)
        return c.magnitude > 0.05 ? c.normalized : nil
    }
}

public struct Mobility: Codable, Equatable, Sendable {
    public var forward = 0.0
    public var back = 0.0
    public var left = 0.0
    public var right = 0.0
    public var turnLeft = 0.0
    public var turnRight = 0.0

    public init() {}
}

public struct Lean: Sendable {
    public static let sideAllowance = 5.0

    public let pitch: Double
    public let roll: Double
    public let total: Double
    public let directional: Bool

    public init(tilt: Tilt, baseline: Tilt, axes: Axes?) {
        total = tilt.degrees(from: baseline)
        guard let axes else {
            pitch = total
            roll = 0
            directional = false
            return
        }
        let c = baseline.normalized.cross(tilt.normalized)
        pitch = asin(max(-1, min(1, c.dot(axes.pitch)))) * 180 / .pi
        roll = asin(max(-1, min(1, c.dot(axes.roll)))) * 180 / .pi
        directional = true
    }

    public func slouching(threshold: Double) -> Bool {
        directional ? pitch >= threshold || abs(roll) >= threshold + Self.sideAllowance : total >= threshold
    }

    public var drop: Double {
        directional ? max(0, pitch, abs(roll) - Self.sideAllowance) : total
    }

    public var direction: String {
        guard directional else { return "from upright" }
        if abs(roll) >= 3, abs(roll) > max(pitch, 0) { return roll > 0 ? "right" : "left" }
        return pitch >= 0 ? "forward" : "back"
    }
}
