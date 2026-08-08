import SwiftUI
import AppKit

struct PomodoroView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VStack(spacing: 28) {
                Picker("Mode", selection: modeBinding) {
                    ForEach(PomodoroMode.allCases) { m in
                        Text(m.label).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 380)
                .disabled(store.pomodoroRunning)

                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                    Circle()
                        .trim(from: 0, to: store.pomodoroProgress)
                        .stroke(store.pomodoroColor.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: store.pomodoroRemaining)
                    VStack(spacing: 4) {
                        Text(store.pomodoroTimeText)
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                        Text(store.pomodoroMode.label)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(store.pomodoroColor)
                    }
                }
                .frame(width: 240, height: 240)

                HStack(spacing: 14) {
                    Button {
                        store.resetPomodoro()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.pomodoroRunning)
                    Button {
                        store.togglePomodoro()
                    } label: {
                        Label(store.pomodoroRunning ? "Pause" : "Start", systemImage: store.pomodoroRunning ? "pause.fill" : "play.fill")
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.pomodoroColor)
                    .keyboardShortcut(.space)
                }

                HStack(spacing: 24) {
                    stat("Today", "\(store.focusSessionsToday)", "tray.full")
                    stat("Total", "\(store.pomodoros.filter { $0.mode == .focus }.count)", "chart.bar.fill")
                    stat("Focus", "\(store.pomodoroMode.minutes) min", "clock")
                }
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var modeBinding: Binding<PomodoroMode> {
        Binding(
            get: { store.pomodoroMode },
            set: { store.setPomodoroMode($0) }
        )
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pomodoro")
                    .font(.title.bold())
                Text("Focus 25 · Short break 5 · Long break 15 — keeps running while you switch tabs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.playPomodoroSound()
            } label: {
                Label("Test sound", systemImage: "speaker.wave.2")
            }
            .buttonStyle(.bordered)
            .help("Play the completion sound")
            Button {
                store.showFloatingTimer = true
                FloatingTimerWindow.shared.show(store: store)
            } label: {
                Label("Floating timer", systemImage: "pin")
            }
            .buttonStyle(.bordered)
            .help("Show a small always-on-top timer window")
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
}
