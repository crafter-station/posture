import CoreMotion
import Foundation

public struct Tilt: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    init(_ gravity: CMAcceleration) {
        self.init(x: gravity.x, y: gravity.y, z: gravity.z)
    }

    var length: Double { (x * x + y * y + z * z).squareRoot() }

    var unit: Tilt {
        let l = length
        return l > 0 ? Tilt(x: x / l, y: y / l, z: z / l) : self
    }

    public func degrees(from other: Tilt) -> Double {
        let a = unit, b = other.unit
        let dot = max(-1, min(1, a.x * b.x + a.y * b.y + a.z * b.z))
        return acos(dot) * 180 / .pi
    }

    func blended(toward next: Tilt, by factor: Double) -> Tilt {
        Tilt(
            x: x + (next.x - x) * factor,
            y: y + (next.y - y) * factor,
            z: z + (next.z - z) * factor
        )
    }

    public static func mean(_ samples: [Tilt]) -> Tilt? {
        guard !samples.isEmpty else { return nil }
        let n = Double(samples.count)
        return Tilt(
            x: samples.map(\.x).reduce(0, +) / n,
            y: samples.map(\.y).reduce(0, +) / n,
            z: samples.map(\.z).reduce(0, +) / n
        ).unit
    }
}

extension Tilt {
    public static let zero = Tilt(x: 0, y: 0, z: 0)

    public func dot(_ other: Tilt) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    public func cross(_ other: Tilt) -> Tilt {
        Tilt(x: y * other.z - z * other.y, y: z * other.x - x * other.z, z: x * other.y - y * other.x)
    }

    public static func + (a: Tilt, b: Tilt) -> Tilt { Tilt(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z) }
    public static func - (a: Tilt, b: Tilt) -> Tilt { Tilt(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z) }
    public static func * (a: Tilt, s: Double) -> Tilt { Tilt(x: a.x * s, y: a.y * s, z: a.z * s) }

    public var normalized: Tilt { unit }
    public var magnitude: Double { length }
}
