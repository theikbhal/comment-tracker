import SwiftUI
import AppKit

private let calendarWeekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
private let calendarColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

struct CalendarView: View {
    @EnvironmentObject var store: Store
    @State private var displayedMonth = Calendar.current.startOfDay(for: Date())
    @State private var selectedDay = dayString(Date())
    @State private var editingEvent: CalendarEvent?
    @State private var showingAddSheet = false

    private var calendar: Calendar { .current }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var gridDays: [Date?] {
        var result: [Date?] = []
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = (firstWeekday + 5) % 7
        for _ in 0..<leadingBlanks { result.append(nil) }
        guard let range = calendar.range(of: .day, in: .month, for: monthStart) else { return result }
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(date)
            }
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private var selectedDayEvents: [CalendarEvent] {
        store.events(on: selectedDay)
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                monthHeader
                Divider()
                weekdayRow
                monthGrid
            }
            Divider()
            dayPanel
        }
        .sheet(item: $editingEvent) { event in
            CalendarEventEditSheet(event: event)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAddSheet) {
            CalendarEventEditSheet(day: selectedDay)
                .environmentObject(store)
        }
    }

    private var monthHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Calendar")
                    .font(.title.bold())
                Text("\(store.calendarEvents.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Button {
                store.requestNotificationPermission()
                store.sendTestCalendarNotification()
            } label: {
                Image(systemName: "bell.badge")
            }
            .buttonStyle(.bordered)
            .help("Send a test notification")
            Button {
                withAnimation { displayedMonth = monthStart }
                selectedDay = dayString(Date())
            } label: {
                Text("Today")
            }
            .buttonStyle(.bordered)
            Button {
                withAnimation { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth }
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            Text(monthTitle)
                .font(.headline)
                .frame(width: 130)
            Button {
                withAnimation { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth }
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
    }

    private var weekdayRow: some View {
        HStack(spacing: 4) {
            ForEach(calendarWeekdays, id: \.self) { day in
                Text(day)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var monthGrid: some View {
        ScrollView {
            LazyVGrid(columns: calendarColumns, spacing: 4) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear
                            .frame(height: 84)
                    }
                }
            }
            .padding(8)
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let day = dayString(date)
        let events = store.events(on: day)
        let isToday = day == dayString(Date())
        let isSelected = day == selectedDay
        let isCurrentMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)

        return VStack(alignment: .leading, spacing: 3) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption.weight(isToday ? .bold : .semibold))
                .foregroundStyle(isToday ? Color.white : (isCurrentMonth ? Color.primary : Color.secondary))
                .frame(width: 22, height: 22)
                .background(isToday ? Color.accentColor : Color.clear, in: Circle())
            ForEach(Array(events.prefix(3).enumerated()), id: \.element.id) { index, event in
                eventChip(event, isSelected: isSelected, dimmed: index >= 2)
            }
            if events.count > 3 {
                Text("+\(events.count - 3) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(4)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
        .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.gray.opacity(0.12), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            selectedDay = day
        }
    }

    private func eventChip(_ event: CalendarEvent, isSelected: Bool, dimmed: Bool) -> some View {
        HStack(spacing: 3) {
            Circle()
                .fill(mindMapColor(event.color))
                .frame(width: 6, height: 6)
            Text(event.time.isEmpty ? event.title : "\(event.time) \(event.title)")
                .font(.system(size: 9))
                .lineLimit(1)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(mindMapColor(event.color).opacity(0.14), in: Capsule())
        .opacity(dimmed ? 0.5 : 1)
        .contentShape(Capsule())
        .onTapGesture {
            selectedDay = event.day
            editingEvent = event
        }
    }

    private var dayPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(selectedDayTitle)
                        .font(.headline)
                    Text("\(selectedDayEvents.count) events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
                .help("Add event")
            }
            .padding(12)
            Divider()
            ScrollView {
                VStack(spacing: 8) {
                    if selectedDayEvents.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 26))
                                .foregroundStyle(.tertiary)
                            Text("No events this day")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button {
                                showingAddSheet = true
                            } label: {
                                Label("Add event", systemImage: "plus")
                            }
                            .buttonStyle(.bordered)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                    } else {
                        ForEach(selectedDayEvents) { event in
                            CalendarEventRowView(event: event) {
                                editingEvent = event
                            }
                        }
                    }
                }
                .padding(10)
            }
        }
        .frame(width: 300)
        .background(.background.secondary)
    }

    private var selectedDayTitle: String {
        guard let date = dateFromDay(selectedDay) else { return selectedDay }
        if dayString(date) == dayString(Date()) {
            return "Today · \(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))"
        }
        return date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
}

struct CalendarEventRowView: View {
    @EnvironmentObject var store: Store
    let event: CalendarEvent
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(mindMapColor(event.color))
                    .frame(width: 8, height: 8)
                Text(event.time.isEmpty ? event.title : "\(event.time) — \(event.title)")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer()
                Button {
                    onEdit?()
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button(role: .destructive) {
                    store.deleteCalendarEvent(event.id)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            if !event.note.isEmpty {
                Text(event.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(mindMapColor(event.color).opacity(0.3), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { onEdit?() }
        .contextMenu {
            Button { onEdit?() } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) {
                store.deleteCalendarEvent(event.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct CalendarEventEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let event: CalendarEvent?
    let day: String?

    @State private var title: String
    @State private var time: String
    @State private var color: String
    @State private var note: String
    @State private var reminder: Int

    init(event: CalendarEvent) {
        self.event = event
        self.day = nil
        _title = State(initialValue: event.title)
        _time = State(initialValue: event.time)
        _color = State(initialValue: event.color)
        _note = State(initialValue: event.note)
        _reminder = State(initialValue: event.reminder)
    }

    init(day: String) {
        self.event = nil
        self.day = day
        _title = State(initialValue: "")
        _time = State(initialValue: "")
        _color = State(initialValue: "blue")
        _note = State(initialValue: "")
        _reminder = State(initialValue: 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event == nil ? "New event" : "Edit event")
                .font(.headline)
            if let day {
                Text(dayLabel(day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Time (optional, e.g. 2:00 PM)", text: $time)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $note)
                .font(.body)
                .frame(minHeight: 90)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 6) {
                Text("Remind me")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Menu {
                    ForEach(calendarReminderPresets, id: \.self) { minutes in
                        Button {
                            reminder = minutes
                        } label: {
                            if reminder == minutes {
                                Label(calendarReminderLabel(minutes), systemImage: "checkmark")
                            } else {
                                Text(calendarReminderLabel(minutes))
                            }
                        }
                    }
                } label: {
                    Text(calendarReminderLabel(reminder))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                Spacer()
            }
            HStack(spacing: 6) {
                ForEach(mindMapColorNames, id: \.self) { colorName in
                    Button {
                        color = colorName
                    } label: {
                        Circle()
                            .fill(mindMapColor(colorName))
                            .frame(width: 18, height: 18)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: color == colorName ? 2 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(event == nil ? "Add" : "Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 400, height: 400)
    }

    private func dayLabel(_ day: String) -> String {
        guard let date = dateFromDay(day) else { return day }
        return date.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    private func save() {
        if reminder > 0 {
            store.requestNotificationPermission()
        }
        if let event {
            store.updateCalendarEvent(id: event.id, title: title, time: time, color: color, note: note, reminder: reminder)
        } else if let day {
            store.addCalendarEvent(title: title, day: day, time: time, color: color, note: note, reminder: reminder)
        }
        dismiss()
    }
}
