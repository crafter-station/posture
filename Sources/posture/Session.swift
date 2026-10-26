import Foundation

@MainActor
final class Session {
    private let sensor = HeadSensor()
    private var heard = false
    private var handler: ((SensorEvent) -> Void)?
    var tolerant = false

    func listen(_ handler: @escaping (SensorEvent) -> Void) {
        let first = self.handler == nil
        self.handler = handler
        guard first else { return }
        do {
            try sensor.start { [self] event in
                if case .tilt = event { heard = true }
                self.handler?(event)
            }
        } catch {
            fail(error)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [self] in
            if !heard, !tolerant { fail(SensorError.silent) }
        }
    }

    func collect(for seconds: Double, then finish: @escaping ([Tilt]) -> Void) {
        var samples: [Tilt] = []
        listen { event in
            if case .tilt(let tilt) = event { samples.append(tilt) }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [self] in
            handler = { _ in }
            finish(samples)
        }
    }
}

func fail(_ error: Error) -> Never {
    FileHandle.standardError.write(Data(("\r\u{1B}[2K" + Format.red("error") + " \(error)\n").utf8))
    exit(2)
}
