import Foundation

struct Settings: Codable {
    var baseline: Tilt?
    var threshold: Double = 15
    var grace: Double = 20
}

struct Day: Codable {
    var watched: Double = 0
    var slouched: Double = 0
    var alerts: Int = 0

    var score: Int {
        watched > 0 ? Int(((1 - slouched / watched) * 100).rounded()) : 100
    }
}

enum Store {
    static let directory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/posture", isDirectory: true)

    private static let settingsURL = directory.appendingPathComponent("settings.json")
    private static let historyURL = directory.appendingPathComponent("history.json")

    static func settings() -> Settings {
        read(settingsURL) ?? Settings()
    }

    static func save(_ settings: Settings) {
        write(settings, to: settingsURL)
    }

    static func history() -> [String: Day] {
        read(historyURL) ?? [:]
    }

    static func record(_ day: Day, on key: String) {
        var all = history()
        all[key] = day
        write(all, to: historyURL)
    }

    static func todayKey(_ date: Date = .now) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }

    private static func read<T: Decodable>(_ url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func write<T: Encodable>(_ value: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
