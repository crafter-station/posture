import Foundation

enum Format {
    static let tty = isatty(STDOUT_FILENO) == 1

    static func duration(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m \(s % 60)s" }
        return "\(s / 3600)h \(s % 3600 / 60)m"
    }

    static func paint(_ text: String, _ code: Int) -> String {
        tty ? "\u{1B}[\(code)m\(text)\u{1B}[0m" : text
    }

    static func green(_ text: String) -> String { paint(text, 32) }
    static func yellow(_ text: String) -> String { paint(text, 33) }
    static func red(_ text: String) -> String { paint(text, 31) }
    static func dim(_ text: String) -> String { paint(text, 2) }
    static func bold(_ text: String) -> String { paint(text, 1) }

    static func meter(_ degrees: Double, threshold: Double, width: Int = 20) -> String {
        let filled = min(width, Int((degrees / (threshold * 2)) * Double(width)))
        let bar = String(repeating: "█", count: filled) + String(repeating: "·", count: width - filled)
        if degrees >= threshold { return red(bar) }
        if degrees >= threshold * 0.6 { return yellow(bar) }
        return green(bar)
    }

    static func json(_ object: [String: Any]) -> String {
        let data = (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data()
        return String(decoding: data, as: UTF8.self)
    }

    static func line(_ text: String) {
        print(text)
        fflush(stdout)
    }

    static func status(_ text: String) {
        print("\r\u{1B}[2K" + text, terminator: "")
        fflush(stdout)
    }
}
