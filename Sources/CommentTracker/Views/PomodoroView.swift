import SwiftUI
import AppKit

struct PomodoroView: View {
    @EnvironmentObject var store: Store
    @State private var mode: PomodoroMode = .focus
    @State private var running = false
    @State private var endTime: Date?
    @State private var remaining = PomodoroMode.focus.minutes * 60
    @State private var startedAt = Date()
    @State private var sessionID: Int?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var total: Int { mode.minutes * 60 }
    private var progress: Double { 1 - Double(remaining) / Double(max(1, total)) }

    private var timeText: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VStack(spacing: 28) {
                Picker("Mode", selection: $mode) {
                    ForEach(PomodoroMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)
                .onChange(of: mode) { _, _ in reset() }

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(modeColor.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: remaining)
                    VStack(spacing: 4) {
                        Text(timeText)
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                        Text(mode.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(modeColor)
                    }
                }
                .frame(width: 240, height: 240)

                HStack(spacing: 14) {
                    Button {
                        reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(running)
                    Button {
                        toggleRun()
                    } label: {
                        Label(running ? "Pause" : "Start", systemImage: running ? "pause.fill" : "play.fill")
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(modeColor)
                    .keyboardShortcut(.space)
                }

                HStack(spacing: 24) {
                    stat("Today", "\(store.focusSessionsToday)", "tray.full")
                    stat("Total", "\(store.pomodoros.filter { $0.mode == .focus }.count)", "chart.bar.fill")
                    stat("Focus", "\(mode.minutes) min", "clock")
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onReceive(ticker) { now in
            guard running, let end = endTime else { return }
            let secs = Int(end.timeIntervalSince(now))
            if secs <= 0 {
                complete()
            } else {
                remaining = secs
            }
        }
        .onAppear {
            remaining = total
        }
    }

    private var modeColor: Color {
        switch mode {
        case .focus: return .red
        case .short: return .green
        case .long: return .blue
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pomodoro")
                    .font(.title.bold())
                Text("Focus 25 · Short break 5 · Long break 15")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    private func stat(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90)
        .padding(.vertical, 10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func toggleRun() {
        if running {
            running = false
        } else {
            startedAt = Date()
            endTime = startedAt.addingTimeInterval(TimeInterval(remaining))
            running = true
            sessionID = store.addPomodoro(mode: mode, startedAt: startedAt)
        }
    }

    private func reset() {
        running = false
        endTime = nil
        remaining = total
    }

    private func complete() {
        if let sessionID {
            store.endPomodoro(id: sessionID)
        }
        store.refresh()
        NSSound(named: "Glass")?.play()
        running = false
        endTime = nil
        if mode == .focus {
            mode = .short
        } else {
            mode = .focus
        }
        remaining = total
        sessionID = nil
    }
}