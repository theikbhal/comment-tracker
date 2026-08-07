import SwiftUI
import AppKit

@MainActor
final class FloatingTimerWindow: NSObject {
    static let shared = FloatingTimerWindow()
    private var panel: NSPanel?
    private var store: Store?

    private override init() {
        super.init()
    }

    func show(store: Store) {
        self.store = store
        if panel == nil {
            let content = NSHostingController(rootView: FloatingTimerView().environmentObject(store))
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 260, height: 150),
                styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.title = "Timer"
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.hidesOnDeactivate = false
            panel.isMovableByWindowBackground = true
            panel.titlebarAppearsTransparent = true
            panel.titleVisibility = .hidden
            panel.contentViewController = content
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.isReleasedWhenClosed = false
            panel.delegate = self
            self.panel = panel
        } else {
            panel?.contentViewController = NSHostingController(rootView: FloatingTimerView().environmentObject(store))
        }
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
    }
}

extension FloatingTimerWindow: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        store?.showFloatingTimer = false
    }
}
struct FloatingTimerView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 10) {
            if store.pomodoroRunning || store.pomodoroRemaining < store.pomodoroTotal {
                pomodoroSection
            } else if store.deepWorkRunning || store.deepWorkSecondsLeft > 0 {
                deepWorkSection
            } else {
                idleSection
            }
        }
        .padding(14)
        .frame(width: 260)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var pomodoroSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(store.pomodoroColor)
                Text("Pomodoro · \(store.pomodoroMode.label)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                closeButton
            }
            Text(store.pomodoroTimeText)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .monospacedDigit()
            HStack(spacing: 10) {
                Button {
                    store.togglePomodoro()
                } label: {
                    Label(store.pomodoroRunning ? "Pause" : "Start", systemImage: store.pomodoroRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(store.pomodoroColor)
                Button {
                    store.resetPomodoro()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var deepWorkSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.indigo)
                Text("Deep Work")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                closeButton
            }
            Text(timeString(store.deepWorkSecondsLeft))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .monospacedDigit()
            HStack(spacing: 10) {
                Button {
                    store.deepWorkRunning ? store.pauseDeepWorkTimer() : store.startDeepWorkTimer()
                } label: {
                    Label(store.deepWorkRunning ? "Pause" : "Resume", systemImage: store.deepWorkRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                Button {
                    store.resetDeepWorkTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var idleSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Timer")
                    .font(.headline)
                Spacer()
                closeButton
            }
            Text("Start a Pomodoro or Deep Work session to see it here — it floats above everything.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var closeButton: some View {
        Button {
            FloatingTimerWindow.shared.close()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .help("Close floating timer")
    }

    private func timeString(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
