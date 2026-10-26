import Foundation

public struct Settings: Codable, Sendable {
    public var baseline: Tilt?
    public var threshold = 15.0
    public var grace = 30.0
    public var sound = true
    public var showAngle = false

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        baseline = try c.decodeIfPresent(Tilt.self, forKey: .baseline)
        threshold = try c.decodeIfPresent(Double.self, forKey: .threshold) ?? threshold
        grace = try c.decodeIfPresent(Double.self, forKey: .grace) ?? grace
        sound = try c.decodeIfPresent(Bool.self, forKey: .sound) ?? sound
        showAngle = try c.decodeIfPresent(Bool.self, forKey: .showAngle) ?? showAngle
    }
}

public struct Slot: Codable, Sendable {
    public var watched = 0.0
    public var slouched = 0.0

    public var upright: Double { watched > 0 ? 1 - slouched / watched : 1 }
}

public struct Day: Codable, Sendable {
    public var watched = 0.0
    public var slouched = 0.0
    public var alerts = 0
    public var bestStreak = 0.0
    public var hours: [String: Slot] = [:]

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        watched = try c.decodeIfPresent(Double.self, forKey: .watched) ?? 0
        slouched = try c.decodeIfPresent(Double.self, forKey: .slouched) ?? 0
        alerts = try c.decodeIfPresent(Int.self, forKey: .alerts) ?? 0
        bestStreak = try c.decodeIfPresent(Double.self, forKey: .bestStreak) ?? 0
        hours = try c.decodeIfPresent([String: Slot].self, forKey: .hours) ?? [:]
    }

    public var score: Int {
        watched > 0 ? Int(((1 - slouched / watched) * 100).rounded()) : 100
    }

    public var hourly: [(hour: Int, slot: Slot)] {
        hours.compactMap { key, slot in Int(key).map { ($0, slot) } }.sorted { $0.hour < $1.hour }
    }

    mutating func add(_ seconds: Double, slouching: Bool, at date: Date) {
        let hour = String(Calendar.current.component(.hour, from: date))
        watched += seconds
        hours[hour, default: Slot()].watched += seconds
        if slouching {
            slouched += seconds
            hours[hour, default: Slot()].slouched += seconds
        }
    }
}

public enum Store {
    public static let directory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".config/posture", isDirectory: true)

    private static let settingsURL = directory.appendingPathComponent("settings.json")
    private static let historyURL = directory.appendingPathComponent("history.json")

    public static func settings() -> Settings {
        read(settingsURL) ?? Settings()
    }

    public static func save(_ settings: Settings) {
        write(settings, to: settingsURL)
    }

    public static func history() -> [String: Day] {
        read(historyURL) ?? [:]
    }

    public static func record(_ day: Day, on key: String) {
        var all = history()
        all[key] = day
        write(all, to: historyURL)
    }

    public static func dayKey(_ date: Date = .now) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }

    public static func recentKeys(_ count: Int, until date: Date = .now) -> [String] {
        (0..<count).reversed().compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: date).map { dayKey($0) }
        }
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
