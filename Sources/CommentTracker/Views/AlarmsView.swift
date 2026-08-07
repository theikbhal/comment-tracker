import SwiftUI
import AppKit

struct AlarmsView: View {
    @EnvironmentObject var store: Store
    @State private var input = ""
    @State private var label = ""
    @State private var editing: AlarmItem?
    @State private var confirmingDelete: AlarmItem?

    private var parsed: Date? {
        parseAlarmInput(input)
    }

    private var previewText: String {
        guard !input.isEmpty else { return "" }
        if let date = parsed {
            return "→ \(alarmDescription(date))"
        }
        return "Try: 15 minutes, 1 hour, 2pm, 8.30pm"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    inputCard
                    if !store.activeAlarms.isEmpty {
                        activeSection
                    }
                    if !store.firedAlarms.isEmpty {
                        firedSection
                    }
                }
                .padding(20)
                .frame(maxWidth: 640, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(item: $editing) { alarm in
            EditAlarmSheet(
                alarm: alarm,
                onSave: { label, date in
                    store.updateAlarm(id: alarm.id, label: label, fireAt: date)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Stop this alarm?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Stop & delete", role: .destructive) {
                if let alarm = confirmingDelete {
                    store.deleteAlarm(alarm.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) {
                confirmingDelete = nil
            }
        } message: {
            Text(confirmingDelete.map { "This removes the alarm \"\($0.label.isEmpty ? "Alarm" : $0.label)\"." } ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Alarms")
                    .font(.title.bold())
                Text("\(store.activeAlarms.count) active · fires in the background, even on another tab")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField("Set an alarm… e.g. 15 minutes, 1 hour, 2pm, 8.30pm", text: $input)
                    .textFieldStyle(.roundedBorder)
                    .font(.body)
                    .onSubmit(commit)
                Button {
                    commit()
                } label: {
                    Label("Set", systemImage: "alarm")
                }
                .buttonStyle(.borderedProminent)
                .disabled(parsed == nil)
                .keyboardShortcut(.defaultAction)
            }
            if !input.isEmpty {
                Text(previewText)
                    .font(.caption)
                    .foregroundStyle(parsed == nil ? .red : .green)
            }
            HStack(spacing: 8) {
                ForEach(alarmQuickPresets, id: \.0) { preset in
                    Button(preset.0) {
                        input = preset.0
                        label = ""
                        commit()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.16), lineWidth: 1))
    }

    private var activeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Active", count: store.activeAlarms.count)
            VStack(spacing: 0) {
                ForEach(store.activeAlarms) { alarm in
                    AlarmRow(alarm: alarm) {
                        editing = alarm
                    } onDelete: {
                        confirmingDelete = alarm
                    }
                    if alarm.id != store.activeAlarms.last?.id {
                        Divider()
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.14), lineWidth: 1))
        }
    }

    private var firedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Fired", count: store.firedAlarms.count)
            VStack(spacing: 0) {
                ForEach(store.firedAlarms) { alarm in
                    HStack(spacing: 10) {
                        Image(systemName: "alarm.fill")
                            .foregroundStyle(.tertiary)
                        Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(alarm.fireAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Button {
                            confirmingDelete = alarm
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.14), lineWidth: 1))
        }
    }

    private func sectionTitle(_ text: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Text(text.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func commit() {
        guard let date = parsed else { return }
        let text = label.trimmingCharacters(in: .whitespacesAndNewlines)
        store.addAlarm(label: text, fireAt: date)
        input = ""
        label = ""
    }
}

// MARK: - Row

struct AlarmRow: View {
    @EnvironmentObject var store: Store
    let alarm: AlarmItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "alarm.waves.left.and.right")
                .font(.system(size: 15))
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(alarm.timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(alarm.countdownText(now: store.now))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
                .monospacedDigit()
            Button {
                store.snoozeAlarm(id: alarm.id)
            } label: {
                Label("Snooze 5m", systemImage: "zzz")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
            }
            .buttonStyle(.borderless)
            .help("Edit alarm")
            Button {
                onDelete()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .help("Stop & delete alarm")
        }
        .padding(10)
        .contentShape(Rectangle())
    }
}

// MARK: - Edit sheet

struct EditAlarmSheet: View {
    @Environment(\.dismiss) private var dismiss
    let alarm: AlarmItem
    let onSave: (String, Date) -> Void

    @State private var label = ""
    @State private var date: Date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Alarm")
                .font(.title2.bold())
            TextField("Label (optional)", text: $label)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 6) {
                Text("Fire time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                DatePicker("Fire time", selection: $date)
                    .labelsHidden()
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(label, date)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(date <= Date())
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
        .onAppear {
            label = alarm.label
            date = alarm.fireAt
        }
    }
}
