import SwiftUI

@main
struct PostureBarApp: App {
    @State private var monitor = Monitor()

    var body: some Scene {
        MenuBarExtra {
            Panel(monitor: monitor)
                .onAppear { monitor.sync() }
        } label: {
            Image(nsImage: monitor.icon)
        }
        .menuBarExtraStyle(.window)

        Window("Posture setup", id: "setup") {
            SetupWindow(monitor: monitor)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultLaunchBehavior(monitor.needsSetup ? .presented : .suppressed)
    }
}
