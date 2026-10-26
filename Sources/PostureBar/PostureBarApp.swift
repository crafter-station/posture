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
    }
}
