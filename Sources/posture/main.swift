import Foundation
import PostureKit

let usage = """
\(Format.bold("posture")) · slouch alerts from your AirPods

  posture                     watch your posture (calibrates on first run)
  posture calibrate           save your upright head position
  posture now                 one reading, exit 0 upright · 1 slouching
  posture stats [--days 7]    daily score, slouch time and nudges
  posture config              show or change settings
  posture doctor              check AirPods, permission and sensor
  posture bar                 open the menu bar app

options
  --threshold <deg>   tilt that counts as slouching (default 15)
  --grace <sec>       how long before a nudge (default 30)
  --repeat <sec>      how often a nudge repeats while slouching, 0 = once (default 90)
  --quiet             notifications without sound
  --json              machine-readable output (JSONL for watch)
"""

struct Arguments {
    var command: String?
    var flags: Set<String> = []
    var values: [String: String] = [:]

    init(_ raw: [String]) {
        var iterator = raw.makeIterator()
        while let arg = iterator.next() {
            if arg.hasPrefix("--") {
                let name = String(arg.dropFirst(2))
                if ["threshold", "grace", "repeat", "days"].contains(name) { values[name] = iterator.next() } else { flags.insert(name) }
            } else if arg == "-h" {
                flags.insert("help")
            } else if command == nil {
                command = arg
            }
        }
    }

    func number(_ name: String) -> Double? {
        values[name].flatMap(Double.init)
    }
}

Responsibility.disclaimTerminal()

let args = Arguments(Array(CommandLine.arguments.dropFirst()))
let json = args.flags.contains("json")

MainActor.assumeIsolated {
    if args.flags.contains("help") || args.command == "help" {
        print(usage)
        exit(0)
    }

    switch args.command {
    case nil, "watch":
        let settings = Store.settings()
        let options = WatchOptions(
            threshold: args.number("threshold") ?? settings.threshold,
            grace: args.number("grace") ?? settings.grace,
            repeatEvery: args.number("repeat") ?? settings.repeatEvery,
            json: json,
            quiet: args.flags.contains("quiet")
        )
        if let baseline = settings.baseline {
            Watch(baseline: baseline, options: options).start()
        } else {
            Calibrate.run { session in
                Watch(baseline: Store.settings().baseline!, options: options, session: session).start()
            }
        }
    case "calibrate":
        Calibrate.run()
    case "now":
        Commands.now(json: json)
    case "stats":
        Commands.stats(json: json, days: Int(args.number("days") ?? 7))
    case "bar":
        Commands.open()
    case "doctor":
        Doctor.run(json: json)
    case "config":
        Commands.config(threshold: args.number("threshold"), grace: args.number("grace"), repeatEvery: args.number("repeat"), json: json)
    case let other?:
        FileHandle.standardError.write(Data("Unknown command \(other)\n\n\(usage)\n".utf8))
        exit(2)
    }
}

dispatchMain()
