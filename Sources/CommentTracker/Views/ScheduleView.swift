import SwiftUI
import AppKit

func dayName(_ day: Int) -> String {
    ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][max(0, day - 1) % 7]
}

struct ScheduleView: View {
    @EnvironmentObject var store: Store
    @State private var editing: ScheduleCell?

    private let days: [Int] = Array(1...7)
    private let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    private var todayCol: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weekday == 1 ? 7 : weekday - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView([.vertical, .horizontal]) {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(scheduleSlotNames.indices, id: \.self) { i in
                        slotRow(i)
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $editing) { cell in
            ScheduleEditSheet(day: cell.day, slot: cell.slot, initialTask: store.scheduleEntry(day: cell.day, slot: cell.slot)?.task ?? "")
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Schedule")
                    .font(.title.bold())
                Text("When to work · what to work on")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(store.schedule.count) planned slots")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(16)
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 110, height: 34)
            ForEach(days, id: \.self) { day in
                let isToday = day == todayCol
                Text(isToday ? "\(dayNames[day - 1]) · today" : dayNames[day - 1])
                    .font(.caption.weight(isToday ? .bold : .semibold))
                    .foregroundStyle(isToday ? .white : .primary)
                    .frame(width: 130, height: 28)
                    .background(isToday ? Color.accentColor : Color.gray.opacity(0.08))
            }
        }
    }

    private func slotRow(_ slot: Int) -> some View {
        HStack(spacing: 0) {
            Text(scheduleSlotNames[slot])
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 110, height: 64)
                .background(Color.gray.opacity(0.06))
            ForEach(days, id: \.self) { day in
                cell(day: day, slot: slot)
            }
        }
    }

    private func cell(day: Int, slot: Int) -> some View {
        let isToday = day == todayCol
        let entry = store.scheduleEntry(day: day, slot: slot)
        return Button {
            editing = .init(day: day, slot: slot)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(entry?.task ?? "")
                    .font(.caption)
                    .foregroundStyle(entry != nil ? .primary : .tertiary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                if entry == nil {
                    Spacer(minLength: 0)
                    Image(systemName: "plus")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(6)
            .frame(width: 130, height: 72, alignment: .topLeading)
            .background(entry != nil ? Color.accentColor.opacity(0.10) : Color.clear)
            .overlay(Rectangle().stroke(isToday ? Color.accentColor.opacity(0.5) : Color.gray.opacity(0.1), lineWidth: isToday ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}

struct ScheduleCell: Identifiable {
    var id: String { "\(day)-\(slot)" }
    var day: Int
    var slot: Int
}

struct ScheduleEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let day: Int
    let slot: Int
    @State private var task: String

    init(day: Int, slot: Int, initialTask: String) {
        self.day = day
        self.slot = slot
        _task = State(initialValue: initialTask)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(dayName) · \(scheduleSlotNames[slot])")
                .font(.headline)
            TextField("What are you working on?", text: $task)
                .textFieldStyle(.roundedBorder)
            Text("Leave empty to clear this slot.")
                .font(.caption)
                .foregroundStyle(.tertiary)
            HStack {
                Spacer()
                Button("Clear") {
                    store.clearScheduleSlot(day: day, slot: slot)
                    dismiss()
                }
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    store.setScheduleTask(day: day, slot: slot, task: task)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 360, height: 220)
    }

    private var dayName: String {
        ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"][day - 1]
    }
}