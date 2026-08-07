import SwiftUI
import AppKit

struct DeepWorkView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 24) {
                    timerCard
                    statsRow
                    if !store.deepWork.isEmpty {
                        historySection
                    }
                }
                .padding(20)
                .frame(maxWidth: 620, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Deep Work")
                    .font(.title.bold())
                Text("A dedicated block. Keeps running while you switch tabs.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
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

    private var timerCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: store.deepWorkProgress)
                    .stroke(progressColor.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(timeString(store.deepWorkSecondsLeft))
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                    Text(store.deepWorkRunning ? "Deep work in progress" : (store.deepWorkSecondsLeft == 0 ? "Ready" : "Paused"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            if !store.deepWorkRunning {
                Picker("Block length", selection: minutesBinding) {
                    ForEach(deepWorkPresets, id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 460)
                .disabled(store.deepWorkSecondsLeft != 0)
            }

            HStack(spacing: 14) {
                if store.deepWorkRunning {
                    Button {
                        store.pauseDeepWorkTimer()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button {
                        store.startDeepWorkTimer()
                    } label: {
                        Label(store.deepWorkSecondsLeft == 0 ? "Start" : "Resume", systemImage: "play.fill")
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                Button {
                    store.resetDeepWorkTimer()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .frame(minWidth: 90)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.16), lineWidth: 1))
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { store.deepWorkSelectedMinutes },
            set: { store.deepWorkSelectedMinutes = $0 }
        )
    }

    private var statsRow: some View {
        HStack(spacing: 20) {
            stat("Today", text: "\(store.deepWorkMinutesToday) min")
            stat("Sessions", text: "\(store.deepWork.count)")
            stat("Last", text: store.deepWork.first.map { "\($0.minutes) min" } ?? "—")
        }
    }

    private func stat(_ label: String, text: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("History")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(store.deepWork) { session in
                    HStack(spacing: 10) {
                        Image(systemName: session.completed ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(session.completed ? .green : .red)
                        Text("\(session.minutes) min block")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button(role: .destructive) {
                            store.deleteDeepWork(session.id)
                        } label: {
                            Label("Delete session", systemImage: "trash")
                        }
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.14), lineWidth: 1))
        }
    }

    private var progressColor: Color {
        let s = store.deepWorkSecondsLeft
        if s <= 60 { return .red }
        if s <= 300 { return .orange }
        return .indigo
    }

    private func timeString(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}
