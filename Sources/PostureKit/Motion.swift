import CoreMotion
import Foundation

public struct Quat: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double
    public var w: Double

    public init(x: Double, y: Double, z: Double, w: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    init(_ q: CMQuaternion) {
        self.init(x: q.x, y: q.y, z: q.z, w: q.w)
    }

    public var inverse: Quat { Quat(x: -x, y: -y, z: -z, w: w) }

    public static func * (a: Quat, b: Quat) -> Quat {
        Quat(
            x: a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y,
            y: a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x,
            z: a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w,
            w: a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
        )
    }

    public func relative(to reference: Quat) -> Quat {
        reference.inverse * self
    }

    public var degrees: Double {
        2 * acos(min(1, abs(w))) * 180 / .pi
    }

    public var rotation: Tilt {
        let q = w < 0 ? Quat(x: -x, y: -y, z: -z, w: -w) : self
        let s = (1 - q.w * q.w).squareRoot()
        guard s > 1e-6 else { return .zero }
        let angle = 2 * acos(min(1, q.w))
        return Tilt(x: q.x / s * angle, y: q.y / s * angle, z: q.z / s * angle)
    }
}

public struct Motion: Sendable {
    public let gravity: Tilt
    public let attitude: Quat
}
