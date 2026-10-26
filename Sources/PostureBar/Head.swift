import SwiftUI

struct HeadPose: Equatable {
    var pitch = 0.0
    var roll = 0.0
    var yaw = 0.0

    static let center = HeadPose()
}

struct HeadView: View {
    var pose: HeadPose
    var tint: Color = .primary

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 3.6
            let origin = CGPoint(x: size.width / 2, y: size.height * 0.42)
            let project = { (p: Vec) in CGPoint(x: origin.x + p.x * scale, y: origin.y - p.y * scale) }

            var body = Path()
            for side in HeadModel.torso { body.addLines(side.map { project(HeadModel.camera($0)) }) }
            context.stroke(body, with: .color(tint.opacity(0.28)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))

            let center = HeadModel.place(Vec(x: 0, y: 0, z: 0), pose)
            let silhouette = Path(ellipseIn: CGRect(x: -scale, y: -scale * HeadModel.height, width: scale * 2, height: scale * HeadModel.height * 2))
                .applying(CGAffineTransform(rotationAngle: pose.roll * .pi / 180).concatenating(CGAffineTransform(translationX: project(center).x, y: project(center).y)))
            context.fill(silhouette, with: .color(tint.opacity(0.05)))

            for line in HeadModel.lines {
                let points = line.points.map { HeadModel.place($0, pose) }
                for (a, b) in zip(points, points.dropFirst()) {
                    let depth = (a.z + b.z) / 2
                    let visibility = max(0, min(1, (depth + 0.15) / 0.45))
                    var segment = Path()
                    segment.move(to: project(a))
                    segment.addLine(to: project(b))
                    context.stroke(segment, with: .color(tint.opacity(line.weight.opacity * (0.1 + 0.9 * visibility))), style: StrokeStyle(lineWidth: line.weight.width, lineCap: .round))
                }
            }

            for eye in HeadModel.eyes {
                let p = HeadModel.place(eye, pose)
                guard p.z > 0.4 else { continue }
                let c = project(p)
                context.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(tint.opacity(0.9)))
            }
        }
    }
}

struct Vec {
    var x: Double
    var y: Double
    var z: Double

    static func - (a: Vec, b: Vec) -> Vec { Vec(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z) }
    static func + (a: Vec, b: Vec) -> Vec { Vec(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z) }

    func rotatedX(_ degrees: Double) -> Vec {
        let r = degrees * .pi / 180
        return Vec(x: x, y: y * cos(r) - z * sin(r), z: y * sin(r) + z * cos(r))
    }

    func rotatedY(_ degrees: Double) -> Vec {
        let r = degrees * .pi / 180
        return Vec(x: x * cos(r) + z * sin(r), y: y, z: -x * sin(r) + z * cos(r))
    }

    func rotatedZ(_ degrees: Double) -> Vec {
        let r = degrees * .pi / 180
        return Vec(x: x * cos(r) + y * sin(r), y: -x * sin(r) + y * cos(r), z: z)
    }
}

enum HeadModel {
    enum Weight {
        case grid
        case feature

        var opacity: Double { self == .grid ? 0.35 : 0.95 }
        var width: Double { self == .grid ? 0.8 : 1.6 }
    }

    struct Line {
        let points: [Vec]
        let weight: Weight
    }

    static let height = 1.15
    static let depth = 1.05
    static let pivot = Vec(x: 0, y: -1.0, z: 0)
    static let view = 10.0

    static func surface(lat: Double, lon: Double, lift: Double = 1) -> Vec {
        let a = lat * .pi / 180, o = lon * .pi / 180
        return Vec(x: cos(a) * sin(o) * lift, y: sin(a) * height * lift, z: cos(a) * cos(o) * depth * lift)
    }

    static func camera(_ p: Vec) -> Vec {
        p.rotatedX(view)
    }

    static func place(_ p: Vec, _ pose: HeadPose) -> Vec {
        camera((p - pivot).rotatedY(pose.yaw).rotatedX(pose.pitch).rotatedZ(pose.roll) + pivot)
    }

    static let lines: [Line] = {
        var lines: [Line] = []
        for lat in [-45.0, -15, 15, 45] {
            lines.append(Line(points: stride(from: 0.0, through: 360, by: 10).map { surface(lat: lat, lon: $0) }, weight: .grid))
        }
        for lon in stride(from: 0.0, to: 360, by: 30) {
            lines.append(Line(points: stride(from: -80.0, through: 80, by: 8).map { surface(lat: $0, lon: lon) }, weight: .grid))
        }
        lines.append(Line(points: [surface(lat: 2, lon: 0), surface(lat: -12, lon: 0, lift: 1.2), surface(lat: -17, lon: 0)], weight: .feature))
        lines.append(Line(points: stride(from: -20.0, through: 20, by: 5).map { surface(lat: -33 - cos($0 * .pi / 40) * 3, lon: $0) }, weight: .feature))
        for side in [-1.0, 1.0] {
            lines.append(Line(points: stride(from: 0.0, through: 360, by: 30).map { t in
                let r = t * .pi / 180
                return Vec(x: side * 1.04, y: -0.05 + 0.24 * sin(r), z: -0.05 + 0.13 * cos(r))
            }, weight: .feature))
        }
        return lines
    }()

    static let eyes = [surface(lat: 12, lon: -30, lift: 1.01), surface(lat: 12, lon: 30, lift: 1.01)]

    static let torso: [[Vec]] = [-1.0, 1.0].map { side in
        [Vec(x: side * 0.36, y: -0.95, z: 0), Vec(x: side * 0.42, y: -1.5, z: 0), Vec(x: side * 1.35, y: -1.75, z: 0), Vec(x: side * 1.75, y: -2.35, z: 0)]
    }
}
