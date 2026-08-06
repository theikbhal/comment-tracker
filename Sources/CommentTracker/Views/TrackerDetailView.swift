import SwiftUI

struct TrackerDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let trackerID: Int

    @State private var monthDate = Date()
    @State private var editingDay: String?

    private var tracker: Tracker? { store.trackerByID(trackerID) }

    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let tracker {
                ScrollView {
                    VStack(spacing: 16) {
                        statsRow(tracker)
                        calendar(tracker)
                    }
                    .padding(20)
                }
            }
            Divider()
            footer
        }
        .frame(width: 520, height: 620)
        .sheet(item: Binding(
            get: { editingDay.map { DayDraft(trackerID: trackerID, day: $0) } },
            set: { editingDay = $0?.day }
        )) { draft in
            DayEditorView(trackerID: draft.trackerID, day: draft.day)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let tracker {
                Image(systemName: tracker.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(tracker.color.gradient)
                VStack(alignment: .leading, spacing: 1) {
                    Text(tracker.name)
                        .font(.title2.bold())
                    Text(tracker.category + (tracker.scheduleNote.isEmpty ? "" : " · " + tracker.scheduleNote))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Close") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private func statsRow(_ tracker: Tracker) -> some View {
        HStack(spacing: 12) {
            StatBadge(
                title: "done this month",
                value: "\(store.monthDoneCount(for: tracker.id, inMonthOf: monthDate))",
                systemImage: "calendar.badge.checkmark"
            )
            StatBadge(
                title: "streak",
                value: "\(store.streak(for: tracker.id))",
                systemImage: "flame"
            )
            if tracker.isCounter {
                StatBadge(
                    title: "today",
                    value: "\(store.count(for: tracker.id, on: dayString(Date())))",
                    systemImage: "plus.circle"
                )
            }
        }
    }

    private func calendar(_ tracker: Tracker) -> some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    monthDate = Calendar.current.date(byAdding: .month, value: -1, to: monthDate) ?? monthDate
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                Spacer()
                VStack(spacing: 0) {
                    Text(monthTitle)
                        .font(.headline)
                    Text(tracker.isCounter ? "tap a day to set count + note" : "tap a day to add note")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    monthDate = Calendar.current.date(byAdding: .month, value: 1, to: monthDate) ?? monthDate
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Button("Today") {
                    monthDate = Date()
                }
                .buttonStyle(.borderless)
                Spacer()
                Text("\(store.monthDoneCount(for: tracker.id, inMonthOf: monthDate)) / \(daysInMonth) days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack {
                ForEach(Array(weekdays.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(dayCells(tracker), id: \.self) { cell in
                    dayCell(tracker, cell)
                }
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthDate)
    }

    private var daysInMonth: Int {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthDate)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return 30 }
        return range.count
    }

    private struct DayCell: Hashable {
        let key: String
        let isBlank: Bool
    }

    private func dayCells(_ tracker: Tracker) -> [DayCell] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: monthDate)
        guard let first = cal.date(from: comps),
              let range = cal.range(of: .day, in: .month, for: first) else { return [] }
        let firstWeekday = cal.component(.weekday, from: first)
        var cells: [DayCell] = []
        for _ in 0..<(firstWeekday - 1) {
            cells.append(DayCell(key: "", isBlank: true))
        }
        for day in 0..<range.count {
            let d = cal.date(byAdding: .day, value: day, to: first)!
            cells.append(DayCell(key: dayString(d), isBlank: false))
        }
        return cells
    }

    private func dayCell(_ tracker: Tracker, _ cell: DayCell) -> some View {
        let isBlank = cell.isBlank
        let isToday = cell.key == dayString(Date())
        let done = isDone(tracker, cell.key)
        let value = counterValue(tracker, cell.key)
        let hasNote = hasNoteOn(tracker, cell.key)

        return VStack(spacing: 3) {
            if isBlank {
                Color.clear
            } else {
                Text(dayNumber(cell.key))
                    .font(.caption.weight(done ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(done ? .white : .primary)
                if tracker.isCounter {
                    Text("\(value)")
                        .font(.system(size: 9, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(done ? .white.opacity(0.9) : .secondary)
                }
                if hasNote {
                    Circle()
                        .fill(done ? Color.white.opacity(0.85) : tracker.color)
                        .frame(width: 4, height: 4)
                } else if !tracker.isCounter {
                    Color.clear.frame(height: 4)
                }
            }
        }
        .frame(height: 38)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(done
                    ? AnyShapeStyle(tracker.color.gradient)
                    : AnyShapeStyle(Color.gray.opacity(isToday ? 0.25 : 0.05)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday ? tracker.color.opacity(0.7) : Color.clear, lineWidth: 1.5)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            if !isBlank {
                editingDay = cell.key
            }
        }
    }

    private func dayNumber(_ key: String) -> String {
        guard let d = dateFromDay(key) else { return "" }
        return "\(Calendar.current.component(.day, from: d))"
    }

    private func isDone(_ tracker: Tracker, _ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return store.isDone(trackerID: tracker.id, on: key)
    }

    private func counterValue(_ tracker: Tracker, _ key: String) -> Int {
        guard !key.isEmpty else { return 0 }
        return store.count(for: tracker.id, on: key)
    }

    private func hasNoteOn(_ tracker: Tracker, _ key: String) -> Bool {
        guard !key.isEmpty else { return false }
        return !store.note(for: tracker.id, on: key).isEmpty
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}

struct DayDraft: Identifiable {
    let trackerID: Int
    let day: String
    var id: String { "\(trackerID)-\(day)" }
}

// MARK: - Day Editor

struct DayEditorView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let trackerID: Int
    let day: String

    @State private var count = 0
    @State private var note = ""

    private var tracker: Tracker? { store.trackerByID(trackerID) }
    private var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d yyyy"
        return dateFromDay(day).map { f.string(from: $0) } ?? day
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                if let tracker {
                    Image(systemName: tracker.icon)
                        .foregroundStyle(tracker.color)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(tracker.name)
                            .font(.headline)
                        Text(dayLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                Spacer()
            }

            if let tracker {
                if tracker.isCounter {
                    HStack(spacing: 14) {
                        Text("Count")
                            .font(.headline)
                        Spacer()
                        Button {
                            count = max(0, count - 1)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.borderless)
                        Text("\(count)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                            .frame(minWidth: 50)
                        Button {
                            count += 1
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 24))
                        }
                        .buttonStyle(.borderless)
                        Text("of \(tracker.target)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Toggle(isOn: Binding(
                        get: { count > 0 },
                        set: { count = $0 ? 1 : 0 }
                    )) {
                        Text(count > 0 ? "Done — checked" : "Mark as done")
                            .font(.headline)
                    }
                    .toggleStyle(.switch)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Label("Note", systemImage: "note.text")
                        .font(.headline)
                    TextEditor(text: $note)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .frame(minHeight: 90)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        )
                }
            }

            HStack {
                Button(role: .destructive) {
                    count = 0
                    note = ""
                    save()
                    dismiss()
                } label: {
                    Label("Clear day", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Save") {
                    save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 420)
        .onAppear {
            count = store.count(for: trackerID, on: day)
            note = store.note(for: trackerID, on: day)
        }
    }

    private func save() {
        store.setCount(trackerID, on: day, count)
        store.setNote(trackerID, on: day, note)
    }
}
