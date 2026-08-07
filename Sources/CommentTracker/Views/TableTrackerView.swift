import SwiftUI
import AppKit

private let tableWindowDays = 14
private let tableColWidth: CGFloat = 36

struct TableTrackerView: View {
    @EnvironmentObject var store: Store
    @State private var selectedTableID: Int?
    @State private var windowEnd = Date()
    @State private var showingNewTable = false
    @State private var showingNewRow = false
    @State private var showingTableMenu = false
    @State private var renameTable: TableTracker?
    @State private var renameRow: TableRow?

    private var tables: [TableTracker] { store.tableTrackers }

    private var selectedTable: TableTracker? {
        guard let id = selectedTableID else { return tables.first }
        return tables.first { $0.id == id }
    }

    private var days: [Date] {
        guard let end = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: windowEnd) else { return [] }
        return (0..<tableWindowDays).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset - (tableWindowDays - 1), to: end)
        }
    }

    private var dayKeys: [String] { days.map { dayString($0) } }

    private var visibleRows: [TableRow] {
        guard let table = selectedTable else { return [] }
        return store.tableRows(for: table.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let table = selectedTable {
                grid(table)
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showingNewTable) {
            NameSheet(title: "New Table", placeholder: "Table name", buttonLabel: "Add") { name in
                let id = store.addTableTracker(name: name)
                if let id { selectedTableID = id }
            }
        }
        .sheet(isPresented: $showingNewRow) {
            if let table = selectedTable {
                NameSheet(title: "Add Row to \"\(table.name)\"", placeholder: "Row label", buttonLabel: "Add") { label in
                    store.addTableRow(tableID: table.id, label: label)
                }
            }
        }
        .sheet(item: $renameTable) { table in
            NameSheet(title: "Rename Table", placeholder: "Table name", buttonLabel: "Save", initial: table.name) { name in
                store.renameTableTracker(id: table.id, name: name)
            }
        }
        .sheet(item: $renameRow) { row in
            NameSheet(title: "Rename Row", placeholder: "Row label", buttonLabel: "Save", initial: row.label) { label in
                store.renameTableRow(id: row.id, label: label)
            }
        }
        .confirmationDialog("Delete this table and all its rows?", isPresented: $showingTableMenu, titleVisibility: .visible) {
            Button("Delete Table", role: .destructive) {
                if let table = selectedTable {
                    store.deleteTableTracker(table.id)
                    selectedTableID = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Table Tracker")
                    .font(.title.bold())
                Text(tables.isEmpty ? "Spreadsheet-style habits" : "\(tables.count) table\(tables.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()

            if !tables.isEmpty {
                Menu {
                    ForEach(tables) { t in
                        Button(t.name) { selectedTableID = t.id }
                    }
                    Divider()
                    Button {
                        showingNewTable = true
                    } label: {
                        Label("New Table…", systemImage: "plus")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tablecells")
                            .foregroundStyle(.indigo)
                        Text(selectedTable?.name ?? "Tables")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            windowNavigator

            Button {
                showingNewTable = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.bordered)
            .help("New table")
            Button {
                renameTable = selectedTable
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.bordered)
            .disabled(selectedTable == nil)
            .help("Rename table")
            Button {
                showingTableMenu = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(selectedTable == nil)
            .help("Delete table")
            Button {
                showingNewRow = true
            } label: {
                Label("Add Row", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedTable == nil)
        }
        .padding(16)
    }

    private var windowNavigator: some View {
        HStack(spacing: 6) {
            Button {
                windowEnd = Calendar.current.date(byAdding: .day, value: -tableWindowDays, to: windowEnd) ?? windowEnd
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .help("Earlier")
            Button {
                windowEnd = Date()
            } label: {
                Text(windowLabel)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .buttonStyle(.bordered)
            .help("Jump to today")
            Button {
                windowEnd = Calendar.current.date(byAdding: .day, value: tableWindowDays, to: windowEnd) ?? windowEnd
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .help("Later")
        }
    }

    private var windowLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        guard let first = days.first, let last = days.last else { return "" }
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    private func grid(_ table: TableTracker) -> some View {
        let rows = visibleRows
        let todayKey = dayString(Date())
        return ScrollView([.horizontal, .vertical], showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                // Day header row
                HStack(spacing: 0) {
                    HStack(spacing: 6) {
                        Text("\(rows.count) rows")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(width: 200, alignment: .leading)
                        Spacer()
                    }
                    .frame(width: 232)
                    ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                        dayHeader(day, isToday: dayString(day) == todayKey)
                    }
                    Color.clear.frame(width: tableColWidth, height: 1)
                }
                .padding(.bottom, 6)

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    rowView(row, isLast: index == rows.count - 1)
                }

                if rows.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tablecells")
                            .font(.system(size: 28))
                            .foregroundStyle(.tertiary)
                        Text("No rows yet — click Add Row to start tracking")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Button {
                            showingNewRow = true
                        } label: {
                            Label("Add Row", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func dayHeader(_ day: Date, isToday: Bool) -> some View {
        VStack(spacing: 2) {
            Text(weekdayLetter(day))
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isToday ? Color.accentColor : .secondary)
            Text("\(Calendar.current.component(.day, from: day))")
                .font(.caption.weight(isToday ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(isToday ? Color.accentColor : .primary)
        }
        .frame(width: tableColWidth)
        .padding(.vertical, 4)
        .background(isToday ? Color.accentColor.opacity(0.1) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
    }

    private func weekdayLetter(_ date: Date) -> String {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        let idx = Calendar.current.component(.weekday, from: date) - 1
        return letters[max(0, min(6, idx))]
    }

    private func rowView(_ row: TableRow, isLast: Bool) -> some View {
        let done = store.tableDoneCount(tableID: row.tableId, rowID: row.id, in: dayKeys)
        let total = dayKeys.count
        let allDone = done == total
        return HStack(spacing: 0) {
            HStack(spacing: 6) {
                Button {
                    store.moveTableRow(id: row.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Move up")
                Button {
                    store.moveTableRow(id: row.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Move down")
                Text(row.label)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .frame(width: 130, alignment: .leading)
                Text("\(done)/\(total)")
                    .font(.caption2)
                    .foregroundStyle(done == 0 ? Color.secondary.opacity(0.4) : (allDone ? Color.green : Color.orange))
                    .monospacedDigit()
                    .frame(width: 40, alignment: .leading)
                Menu {
                    Button {
                        renameRow = row
                    } label: {
                        Label("Rename…", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        store.deleteTableRow(id: row.id)
                    } label: {
                        Label("Delete row", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                Spacer()
            }
            .frame(width: 232)
            ForEach(dayKeys, id: \.self) { day in
                cell(row: row, day: day)
            }
            Color.clear.frame(width: tableColWidth, height: 1)
        }
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color.gray.opacity(0.08))
                    .frame(height: 1)
            }
        }
    }

    private func cell(row: TableRow, day: String) -> some View {
        let done = store.isCellDone(tableID: row.tableId, rowID: row.id, day: day)
        let isToday = day == dayString(Date())
        return Button {
            store.toggleCell(tableID: row.tableId, rowID: row.id, day: day)
        } label: {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 16))
                .foregroundStyle(done ? Color.green : (isToday ? Color.accentColor : Color.secondary.opacity(0.5)))
        }
        .buttonStyle(.plain)
        .frame(width: tableColWidth, height: 22)
        .background(isToday ? Color.accentColor.opacity(0.08) : Color.clear, in: RoundedRectangle(cornerRadius: 5))
        .help("\(day) · \(row.label)")
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tablecells")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No tables yet — track habits or routines in a spreadsheet grid")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showingNewTable = true
            } label: {
                Label("New Table", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Name sheet

struct NameSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let placeholder: String
    let buttonLabel: String
    var initial = ""
    let onSave: (String) -> Void

    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title2.bold())
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(action: submit) {
                    Label(buttonLabel, systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
        .onAppear { text = initial }
    }

    private func submit() {
        onSave(text)
        dismiss()
    }
}
