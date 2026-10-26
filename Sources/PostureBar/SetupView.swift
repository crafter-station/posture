import PostureKit
import SwiftUI

struct SetupWindow: View {
    let monitor: Monitor
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        Group {
            if let flow = monitor.setup {
                SetupView(flow: flow) { dismissWindow(id: "setup") }
            } else {
                Color.clear
            }
        }
        .frame(width: 440, height: 620)
        .onAppear {
            monitor.beginSetup()
            NSApp.activate()
        }
        .onDisappear { monitor.endSetup() }
    }
}

struct SetupView: View {
    let flow: SetupFlow
    let close: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Dots(current: flow.step)
            ZStack {
                ring
                TimelineView(.animation) { context in
                    HeadView(pose: pose(at: context.date), tint: flow.step == .done ? .accentColor : .primary)
                        .animation(.smooth(duration: 0.15), value: flow.live)
                }
                .padding(18)
            }
            .frame(width: 270, height: 270)
            VStack(spacing: 8) {
                Text(flow.step.title).font(.title2.weight(.semibold))
                Text(flow.step.instruction)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                status.font(.callout.weight(.medium)).padding(.top, 4)
            }
            .frame(maxWidth: 340)
            .animation(.snappy, value: flow.step)
            if flow.step == .done, flow.mobility.forward > 0 { MobilityGrid(mobility: flow.mobility) }
            Spacer(minLength: 0)
            actions
        }
        .padding(28)
    }

    @ViewBuilder
    private var ring: some View {
        let visible = flow.isMove || flow.stage == .measuring
        Circle().stroke(.primary.opacity(visible ? 0.08 : 0), lineWidth: 3)
        Circle()
            .trim(from: 0, to: visible ? flow.progress : 0)
            .stroke(flow.stage == .returning ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .rotationEffect(.degrees(-90))
            .animation(.smooth(duration: 0.2), value: flow.progress)
    }

    @ViewBuilder
    private var status: some View {
        if let message = flow.message {
            Text(message).foregroundStyle(.orange).multilineTextAlignment(.center)
        } else {
            switch (flow.step, flow.stage) {
            case (.intro, _):
                Label(flow.receiving ? "AirPods connected" : "Waiting for your AirPods…", systemImage: flow.receiving ? "checkmark.circle.fill" : "airpods")
                    .foregroundStyle(flow.receiving ? Color.green : Color.secondary)
            case (_, .centering): Text("Look straight ahead to begin").foregroundStyle(.secondary)
            case (_, .moving): Text("Keep going…").foregroundStyle(.secondary)
            case (_, .returning): Text("Nice. Now back to center.").foregroundStyle(.green)
            case (_, .countdown(let n)): Text("Measuring in \(n)…").foregroundStyle(.secondary)
            case (_, .measuring): Text("Hold still…").foregroundStyle(.secondary)
            default: Text(" ")
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        HStack {
            switch flow.step {
            case .intro:
                if flow.canSkipMoves {
                    Button("Only recalibrate posture") { flow.skipToPosture() }.buttonStyle(.link)
                }
                Spacer()
                Button("Start") { flow.start() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(!flow.receiving)
            case .done:
                Spacer()
                Button("Done", action: close)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            default:
                Button("Cancel", action: close).buttonStyle(.link)
                Spacer()
            }
        }
        .controlSize(.large)
    }

    private func pose(at date: Date) -> HeadPose {
        switch flow.step {
        case .done:
            return flow.live
        case .intro:
            return flow.step.guide(date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 6) / 6)
        default:
            guard flow.stage != .returning, flow.stage != .centering else { return .center }
            let phase = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.8) / 2.8
            return flow.step.guide((1 - cos(phase * 2 * .pi)) / 2)
        }
    }
}

private struct Dots: View {
    let current: SetupFlow.Step

    var body: some View {
        HStack(spacing: 6) {
            ForEach(SetupFlow.Step.moves + [.posture], id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= current.rawValue ? AnyShapeStyle(.primary) : AnyShapeStyle(.primary.opacity(0.15)))
                    .frame(width: step == current ? 18 : 6, height: 6)
            }
        }
        .animation(.snappy, value: current)
        .opacity(current == .intro ? 0 : 1)
    }
}

private struct MobilityGrid: View {
    let mobility: Mobility

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your range of motion").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Grid(horizontalSpacing: 18, verticalSpacing: 8) {
                GridRow {
                    cell("Down", mobility.forward)
                    cell("Tilt left", mobility.left)
                    cell("Turn left", mobility.turnLeft)
                }
                GridRow {
                    cell("Up", mobility.back)
                    cell("Tilt right", mobility.right)
                    cell("Turn right", mobility.turnRight)
                }
            }
        }
    }

    private func cell(_ title: String, _ degrees: Double) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(Int(degrees.rounded()))°").font(.title3.weight(.semibold)).monospacedDigit()
            Text(title).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(width: 80, alignment: .leading)
    }
}
