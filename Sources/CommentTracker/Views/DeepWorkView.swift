import SwiftUI
import AppKit

struct DeepWorkView: View {
    @EnvironmentObject var store: Store

    @State private var selectedMinutes = 60
    @State private var secondsLeft = 0
    @State private var isRunning = false
    @State private var runningSince = Date()
    @State private var tickerTask: Task<Void, Never>?

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
        .onAppear {
            if secondsLeft == 0 { reset() }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Deep Work")
                    .font(.title.bold())
                Text("A dedicated block. Phones down, one thing.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    private var timerCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(progressColor.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 4) {
                    Text(timeString(secondsLeft))
                        .font(.system(size: 54, weight: .bold, design: .monospaced))
                    Text(isRunning ? "Deep work in progress" : (secondsLeft == 0 ? "Ready" : "Paused"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            if !isRunning {
                Picker("Block length", selection: $selectedMinutes) {
                    ForEach(deepWorkPresets, id: \.self) { m in
                        Text("\(m) min").tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 460)
                .disabled(secondsLeft != 0)
            }

            HStack(spacing: 14) {
                if isRunning {
                    Button {
                        pause()
                    } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button {
                        start()
                    } label: {
                        Label(secondsLeft == 0 ? "Start" : "Resume", systemImage: "play.fill")
                            .frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                }
                Button {
                    reset()
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

    // MARK: - Timer logic

    private var progress: Double {
        guard selectedMinutes > 0 else { return 0 }
        let total = Double(selectedMinutes * 60)
        return Double(secondsLeft) / total
    }

    private var progressColor: Color {
        if secondsLeft <= 60 { return .red }
        if secondsLeft <= 300 { return .orange }
        return .indigo
    }

    private func start() {
        if secondsLeft == 0 {
            secondsLeft = selectedMinutes * 60
        }
        isRunning = true
        runningSince = Date()
        runTicker()
    }

    private func pause() {
        isRunning = false
        tickerTask?.cancel()
        tickerTask = nil
    }

    private func reset() {
        pause()
        secondsLeft = 0
        selectedMinutes = 60
    }

    private func runTicker() {
        tickerTask?.cancel()
        tickerTask = Task { @MainActor in
            while !Task.isCancelled && isRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                let elapsed = Date().timeIntervalSince(runningSince)
                let newValue = max(0, secondsLeft - Int(elapsed))
                secondsLeft = newValue
                if newValue <= 0 {
                    finish()
                    return
                }
            }
        }
    }

    private func finish() {
        isRunning = false
        tickerTask?.cancel()
        tickerTask = nil
        NSSound(named: "Glass")?.play()
        let finished = selectedMinutes
        store.completeDeepWork(minutes: finished)
        secondsLeft = 0
    }

    private func timeString(_ total: Int) -> String {
        let m = total / 60
        let s = total % 60
        return String(format: "%02d:%02d", m, s)
    }
}