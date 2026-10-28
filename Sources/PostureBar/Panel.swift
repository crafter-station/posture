import Charts
import PostureKit
import SwiftUI

struct Panel: View {
    @Bindable var monitor: Monitor
    @State private var showsSettings = false
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if let note = monitor.note {
                Text(note).font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            today
            hours
            week
            Divider()
            if showsSettings { settings }
            footer
        }
        .padding(16)
        .frame(width: 300)
        .animation(.snappy(duration: 0.2), value: showsSettings)
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: Glyph.image(degrees: monitor.phase == .live ? Double(monitor.degrees) : 0, tone: .calm, height: 44))
                .renderingMode(.template)
                .foregroundStyle(monitor.slouching && monitor.phase == .live ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary))
                .frame(width: 44, height: 44)
                .animation(.smooth, value: monitor.degrees)
            VStack(alignment: .leading, spacing: 3) {
                Text(monitor.headline).font(.headline)
                Text(monitor.detail).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private var today: some View {
        HStack(alignment: .top) {
            Stat(title: "Score", value: "\(monitor.today.score)", emphasis: true)
            Stat(title: "Slouched", value: Duration.text(monitor.today.slouched))
            Stat(title: "Nudges", value: "\(monitor.today.alerts)")
            Stat(title: "Best streak", value: Duration.text(monitor.today.bestStreak))
        }
    }

    @ViewBuilder
    private var hours: some View {
        let rows = monitor.today.hourly.filter { $0.slot.watched >= 30 }
        if !rows.isEmpty {
            Section(title: "Today", caption: "\(Duration.text(monitor.today.watched)) tracked") {
                Chart(rows, id: \.hour) { row in
                    BarMark(x: .value("Hour", row.hour), y: .value("Track", 100), width: .fixed(8), stacking: .unstacked)
                        .foregroundStyle(.primary.opacity(0.06))
                        .clipShape(Capsule())
                    BarMark(x: .value("Hour", row.hour), y: .value("Upright", row.slot.upright * 100), width: .fixed(8), stacking: .unstacked)
                        .foregroundStyle(row.slot.upright < 0.7 ? AnyShapeStyle(.orange) : AnyShapeStyle(.primary.opacity(0.75)))
                        .clipShape(Capsule())
                }
                .chartYScale(domain: 0...100)
                .chartYAxis(.hidden)
                .chartXScale(domain: (rows.first!.hour - 1)...(rows.last!.hour + 1))
                .chartXAxis {
                    AxisMarks(values: rows.map(\.hour)) { value in
                        AxisValueLabel {
                            if let hour = value.as(Int.self) { Text(hourLabel(hour)) }
                        }
                    }
                }
                .frame(height: 64)
            }
        }
    }

    private var week: some View {
        Section(title: "This week", caption: weekAverage) {
            Chart(monitor.week) { row in
                BarMark(x: .value("Day", row.key), y: .value("Track", 100), width: .fixed(14), stacking: .unstacked)
                    .foregroundStyle(.primary.opacity(0.06))
                    .clipShape(Capsule())
                BarMark(x: .value("Day", row.key), y: .value("Score", row.day.watched > 0 ? row.day.score : 0), width: .fixed(14), stacking: .unstacked)
                    .foregroundStyle(row.isToday ? AnyShapeStyle(.primary) : AnyShapeStyle(.primary.opacity(0.35)))
                    .clipShape(Capsule())
            }
            .chartYScale(domain: 0...100)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let key = value.as(String.self), let row = monitor.week.first(where: { $0.key == key }) {
                            Text(row.label)
                        }
                    }
                }
            }
            .frame(height: 64)
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            LabeledSlider(title: "Slouch at", value: "\(Int(monitor.settings.threshold))°", amount: binding(\.threshold), range: 8...30, step: 1)
            LabeledSlider(title: "Nudge after", value: Duration.text(monitor.settings.grace), amount: binding(\.grace), range: 10...120, step: 5)
            Toggle("Sound", isOn: binding(\.sound))
            Toggle("Angle in menu bar", isOn: binding(\.showAngle))
            Toggle("Open at login", isOn: Binding(get: { monitor.opensAtLogin }, set: { monitor.setOpensAtLogin($0) }))
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .font(.callout)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button(monitor.needsSetup ? "Set up" : "Calibrate") {
                openWindow(id: "setup")
                NSApp.activate()
            }
            .disabled(monitor.phase == .setup)
            Button(monitor.phase == .paused ? "Resume" : "Pause") { monitor.togglePause() }
                .disabled(monitor.phase == .setup || monitor.phase == .uncalibrated)
            Spacer()
            Button {
                showsSettings.toggle()
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(.borderless)
            .help("Settings")
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit Posture")
        }
        .controlSize(.small)
    }

    private var weekAverage: String {
        let tracked = monitor.week.filter { $0.day.watched > 0 }
        guard !tracked.isEmpty else { return "" }
        return "avg \(tracked.map(\.day.score).reduce(0, +) / tracked.count)"
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return "\(h)\(hour < 12 ? "a" : "p")"
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<PostureKit.Settings, Value>) -> Binding<Value> {
        Binding(get: { monitor.settings[keyPath: keyPath] }, set: { value in monitor.update { $0[keyPath: keyPath] = value } })
    }
}

private struct Stat: View {
    let title: String
    let value: String
    var emphasis = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(emphasis ? .title2.weight(.semibold) : .body.weight(.medium))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct Section<Content: View>: View {
    let title: String
    let caption: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Text(caption).font(.caption2).foregroundStyle(.tertiary)
            }
            content
        }
    }
}

private struct LabeledSlider: View {
    let title: String
    let value: String
    @Binding var amount: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(value).monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: $amount, in: range, step: step)
        }
    }
}
