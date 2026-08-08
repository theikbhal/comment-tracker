import SwiftUI
import AppKit
import UniformTypeIdentifiers

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

            Divider()

            noteSection
            soundSection
            tasksSection
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

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Note for this block", systemImage: "note.text")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("What is this deep work block about?", text: noteBinding)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { store.deepWorkSessionNote },
            set: { store.setDeepWorkSessionNote($0) }
        )
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Alarm sound", systemImage: "speaker.wave.2.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Picker("Sound", selection: soundPresetBinding) {
                    ForEach(deepWorkSoundPresets, id: \.self) { name in
                        Text(name).tag(name)
                    }
                    Text("Custom…").tag("custom")
                }
                .frame(width: 150)
                if store.deepWorkSoundPreset == "custom" {
                    Button {
                        chooseCustomSound()
                    } label: {
                        Label(customSoundLabel, systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                    .help("Choose a sound file")
                }
                Picker("Duration", selection: soundDurationBinding) {
                    ForEach(deepWorkSoundDurations, id: \.self) { d in
                        Text("\(d)s").tag(d)
                    }
                }
                .frame(width: 100)
                Spacer()
                Button {
                    store.playDeepWorkSound()
                } label: {
                    Label("Test", systemImage: "play.circle")
                }
                .buttonStyle(.bordered)
                .help("Play the selected sound for the chosen duration")
            }
        }
    }

    private var customSoundLabel: String {
        guard let path = store.deepWorkSoundCustomPath, !path.isEmpty else { return "Choose file" }
        return (path as NSString).lastPathComponent
    }

    private var soundPresetBinding: Binding<String> {
        Binding(
            get: { store.deepWorkSoundPreset },
            set: { store.setDeepWorkSoundPreset($0) }
        )
    }

    private var soundDurationBinding: Binding<Int> {
        Binding(
            get: { store.deepWorkSoundDuration },
            set: { store.setDeepWorkSoundDuration($0) }
        )
    }

    private func chooseCustomSound() {
        let panel = NSOpenPanel()
        panel.title = "Choose an alarm sound"
        panel.allowedContentTypes = [.audio]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            store.setDeepWorkSoundCustomPath(url.path)
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Tasks for this block", systemImage: "checklist")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.deepWorkTasks.filter { $0.done }.count)/\(store.deepWorkTasks.count) done")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                TextField("Add a task…", text: newTaskText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTask)
                Button {
                    addTask()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
                .disabled(newTaskText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            if store.deepWorkTasks.isEmpty {
                Text("No tasks yet — add what you want to knock out in this block.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                VStack(spacing: 6) {
                    ForEach(store.deepWorkTasks) { task in
                        taskRow(task)
                    }
                }
            }
        }
    }

    @State private var taskText = ""

    private var newTaskText: Binding<String> {
        Binding(
            get: { taskText },
            set: { taskText = $0 }
        )
    }

    private func addTask() {
        let trimmed = taskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addDeepWorkTask(text: trimmed)
        taskText = ""
    }

    private func taskRow(_ task: DeepWorkTask) -> some View {
        HStack(spacing: 8) {
            Button {
                store.toggleDeepWorkTask(id: task.id)
            } label: {
                Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.done ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            Text(task.text)
                .font(.subheadline)
                .strikethrough(task.done, color: .secondary)
                .foregroundStyle(task.done ? .secondary : .primary)
            Spacer()
            Button {
                store.moveDeepWorkTask(id: task.id, direction: -1)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            Button {
                store.moveDeepWorkTask(id: task.id, direction: 1)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            Button {
                store.deleteDeepWorkTask(task.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(8)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(session.minutes) min block")
                                .font(.subheadline.weight(.semibold))
                            if !session.note.isEmpty {
                                Text(session.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
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
