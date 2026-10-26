import AppKit

enum Glyph {
    enum Tone {
        case calm
        case alert
        case idle
    }

    static func image(degrees: Double, tone: Tone, height: CGFloat = 18, label: String? = nil) -> NSImage {
        let scale = height / 18
        let text = label.map { NSAttributedString(string: $0, attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 12 * scale, weight: .medium), .foregroundColor: color(for: tone)]) }
        let textWidth = text.map { ceil($0.size().width) + 3 * scale } ?? 0
        let size = NSSize(width: 16 * scale + textWidth, height: height)
        let image = NSImage(size: size, flipped: false) { _ in
            let color = color(for: tone)
            color.setStroke()
            color.setFill()
            figure(degrees: degrees, scale: scale).forEach { $0.stroke() }
            head(degrees: degrees, scale: scale).fill()
            text?.draw(at: NSPoint(x: 16 * scale + 2 * scale, y: (height - text!.size().height) / 2))
            return true
        }
        image.isTemplate = tone != .alert
        return image
    }

    private static func color(for tone: Tone) -> NSColor {
        switch tone {
        case .calm: .black
        case .alert: .systemOrange
        case .idle: .black.withAlphaComponent(0.4)
        }
    }

    private static func bend(_ degrees: Double) -> CGFloat {
        CGFloat(min(max(degrees / 40, 0), 1))
    }

    private static func neck(_ degrees: Double) -> CGPoint {
        let b = bend(degrees)
        return CGPoint(x: 5 + 3.4 * b, y: 11.2 - 1.6 * b)
    }

    private static func figure(degrees: Double, scale: CGFloat) -> [NSBezierPath] {
        let b = bend(degrees)
        let hip = CGPoint(x: 5, y: 4.4)
        let spine = NSBezierPath()
        spine.move(to: hip * scale)
        spine.curve(to: neck(degrees) * scale, controlPoint1: CGPoint(x: 4.6 - 1.5 * b, y: 7.4) * scale, controlPoint2: CGPoint(x: 4.8 - 0.6 * b, y: 9.8 - 0.4 * b) * scale)

        let legs = NSBezierPath()
        legs.move(to: hip * scale)
        legs.line(to: CGPoint(x: 11.6, y: 4.4) * scale)
        legs.line(to: CGPoint(x: 11.6, y: 0.9) * scale)

        return [spine, legs].map {
            $0.lineWidth = 1.9 * scale
            $0.lineCapStyle = .round
            $0.lineJoinStyle = .round
            return $0
        }
    }

    private static func head(degrees: Double, scale: CGFloat) -> NSBezierPath {
        let angle = (6 + min(max(degrees, 0), 50) * 1.2) * .pi / 180
        let n = neck(degrees)
        let center = CGPoint(x: n.x + 3.4 * sin(angle), y: n.y + 3.4 * cos(angle))
        let r = 2.5
        return NSBezierPath(ovalIn: CGRect(x: (center.x - r) * scale, y: (center.y - r) * scale, width: 2 * r * scale, height: 2 * r * scale))
    }
}

private func * (point: CGPoint, scale: CGFloat) -> CGPoint {
    CGPoint(x: point.x * scale, y: point.y * scale)
}
