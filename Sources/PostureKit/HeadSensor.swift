import CoreMotion
import Foundation

public enum SensorEvent: Sendable {
    case tilt(Tilt)
    case connected
    case disconnected
}

public enum SensorError: Error, CustomStringConvertible {
    case unavailable
    case denied
    case silent

    public var description: String {
        switch self {
        case .unavailable:
            "No motion-capable AirPods found. You need AirPods Pro, AirPods 3 or newer, AirPods Max, or Beats Fit Pro."
        case .denied:
            "Motion access is off. Turn it on in System Settings > Privacy & Security > Motion & Fitness."
        case .silent:
            "No motion data. Put both AirPods in your ears and make sure they are connected to this Mac."
        }
    }
}

@MainActor
public final class HeadSensor: NSObject, CMHeadphoneMotionManagerDelegate {
    private let manager = CMHeadphoneMotionManager()
    private var handler: ((SensorEvent) -> Void)?

    public override init() {
        super.init()
    }

    public var isAvailable: Bool { manager.isDeviceMotionAvailable }

    public static var access: String {
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .authorized: "granted"
        case .denied: "denied"
        case .restricted: "restricted"
        default: "not asked yet"
        }
    }

    public func start(_ handler: @escaping (SensorEvent) -> Void) throws {
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

    public func stop() {
        manager.stopDeviceMotionUpdates()
        handler = nil
    }

    nonisolated public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.handler?(.connected) }
    }

    nonisolated public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in self.handler?(.disconnected) }
    }
}
