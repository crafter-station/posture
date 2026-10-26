import CoreMotion
import Foundation

struct Tilt: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double

    init(x: Double, y: Double, z: Double) {
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

    func degrees(from other: Tilt) -> Double {
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

    static func mean(_ samples: [Tilt]) -> Tilt? {
        guard !samples.isEmpty else { return nil }
        let n = Double(samples.count)
        return Tilt(
            x: samples.map(\.x).reduce(0, +) / n,
            y: samples.map(\.y).reduce(0, +) / n,
            z: samples.map(\.z).reduce(0, +) / n
        ).unit
    }
}
