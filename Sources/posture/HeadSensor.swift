import CoreMotion
import Foundation

enum SensorEvent {
    case tilt(Tilt)
    case connected
    case disconnected
}

enum SensorError: Error, CustomStringConvertible {
    case unavailable
    case denied
    case silent

    var description: String {
        switch self {
        case .unavailable:
            "No motion-capable AirPods found. You need AirPods Pro, AirPods 3 or newer, AirPods Max, or Beats Fit Pro."
        case .denied:
            "Motion access is off. Turn it on in System Settings > Privacy & Security > Motion & Fitness for your terminal app."
        case .silent:
            "No motion data. Put both AirPods in your ears and make sure they are connected to this Mac."
        }
    }
}

@MainActor
final class HeadSensor: NSObject, CMHeadphoneMotionManagerDelegate {
    private let manager = CMHeadphoneMotionManager()
    private var handler: ((SensorEvent) -> Void)?

    func start(_ handler: @escaping (SensorEvent) -> Void) throws {
        guard manager.isDeviceMotionAvailable else { throw SensorError.unavailable }
        if CMHeadphoneMotionManager.authorizationStatus() == .denied { throw SensorError.denied }
        self.handler = handler
        manager.delegate = self
        manager.startDeviceMotionUpdates(to: .main) { motion, _ in
            guard let motion else { return }
            let tilt = Tilt(motion.gravity)
            MainActor.assumeIsolated { self.handler?(.tilt(tilt)) }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        handler = nil
    }

    nonisolated func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.handler?(.connected) }
    }

    nonisolated func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.handler?(.disconnected) }
    }
}
