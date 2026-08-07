import SwiftUI
import AppKit

private func airtableColWidth(_ type: AirtableColType) -> CGFloat {
    switch type {
    case .text, .number: return 160
    case .checkbox: return 52
    case .date: return 118
    }
}

struct AirtableView: View {
    @EnvironmentObject var store: Store
    @State private var selectedAirtableID: Int?
    @State private var showingNewTable = false
    @State private var showingAddColumn = false
    @State private var renameTable: Airtable?
    @State private var renameColumn: AirtableColumn?
    @State private var confirmingDeleteTable = false

    private var tables: [Airtable] { store.airtables }

    private var selectedTable: Airtable? {
        guard let id = selectedAirtableID else { return tables.first }
        return tables.first { $0.id == id }
    }

    private var columns: [AirtableColumn] {
        guard let table = selectedTable else { return [] }
        return store.airtableColumns(for: table.id)
    }

    private var rows: [AirtableRow] {
        guard let table = selectedTable else { return [] }
        return store.airtableRows(for: table.id)
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
            NameSheet(title: "New Table", placeholder: "Table name", buttonLabel: "Create") { name in
                let id = store.addAirtable(name: name)
                if let id { selectedAirtableID = id }
            }
        }
        .sheet(isPresented: $showingAddColumn) {
            if let table = selectedTable {
                AirtableAddColumnSheet { name, type in
                    store.addAirtableColumn(airtableID: table.id, name: name, type: type)
                }
            }
        }
        .sheet(item: $renameTable) { table in
            NameSheet(title: "Rename Table", placeholder: "Table name", buttonLabel: "Save", initial: table.name) { name in
                store.renameAirtable(id: table.id, name: name)
            }
        }
        .sheet(item: $renameColumn) { col in
            NameSheet(title: "Rename Column", placeholder: "Column name", buttonLabel: "Save", initial: col.name) { name in
                store.renameAirtableColumn(id: col.id, name: name)
            }
        }
        .confirmationDialog("Delete this table and all its data?", isPresented: $confirmingDeleteTable, titleVisibility: .visible) {
            Button("Delete Table", role: .destructive) {
                if let table = selectedTable {
                    store.deleteAirtable(table.id)
                    selectedAirtableID = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mini Airtable")
                    .font(.title.bold())
                Text("\(tables.count) table\(tables.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()

            if !tables.isEmpty {
                Menu {
                    ForEach(tables) { t in
                        Button(t.name) { selectedAirtableID = t.id }
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
                            .foregroundStyle(.orange)
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
                confirmingDeleteTable = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(selectedTable == nil)
            .help("Delete table")

            Button {
                showingAddColumn = true
            } label: {
                Label("Column", systemImage: "plus")
            }
            .buttonStyle(.bordered)
            .disabled(selectedTable == nil)
            Button {
                if let table = selectedTable {
                    store.addAirtableRow(airtableID: table.id)
                }
            } label: {
                Label("Row", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedTable == nil)
        }
        .padding(16)
    }

    private func grid(_ table: Airtable) -> some View {
        let cols = columns
        let currentRows = rows
        return VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    columnHeaders(cols)
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(currentRows.enumerated()), id: \.element.id) { index, row in
                                rowView(row, index: index)
                            }
                            if currentRows.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "tablecells")
                                        .font(.system(size: 26))
                                        .foregroundStyle(.tertiary)
                                    Text("No rows yet — click Row to add one")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 50)
                            }
                        }
                    }
                }
                .padding(16)
            }
            if cols.isEmpty {
                VStack(spacing: 8) {
                    Text("Add your first column to start")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button {
                        showingAddColumn = true
                    } label: {
                        Label("Add Column", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.vertical, 30)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func columnHeaders(_ cols: [AirtableColumn]) -> some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: 96, alignment: .leading)
            ForEach(cols) { col in
                columnHeader(col)
            }
            if cols.isEmpty {
                Text("No columns yet")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
            }
        }
        .padding(.bottom, 6)
    }

    private func columnHeader(_ col: AirtableColumn) -> some View {
        HStack(spacing: 4) {
            Image(systemName: col.type.symbol)
                .font(.system(size: 9))
                .foregroundStyle(col.type == .checkbox ? .orange : .secondary)
            Text(col.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Menu {
                Button {
                    renameColumn = col
                } label: {
                    Label("Rename…", systemImage: "pencil")
                }
                Menu {
                    ForEach(AirtableColType.allCases) { t in
                        Button {
                            store.changeAirtableColumnType(id: col.id, type: t)
                        } label: {
                            if t == col.type {
                                Label(t.displayName, systemImage: "checkmark")
                            } else {
                                Text(t.displayName)
                            }
                        }
                    }
                } label: {
                    Label("Type", systemImage: "arrow.triangle.2.circlepath")
                }
                Divider()
                Button {
                    store.moveAirtableColumn(id: col.id, direction: -1)
                } label: {
                    Label("Move left", systemImage: "chevron.left")
                }
                Button {
                    store.moveAirtableColumn(id: col.id, direction: 1)
                } label: {
                    Label("Move right", systemImage: "chevron.right")
                }
                Divider()
                Button(role: .destructive) {
                    store.deleteAirtableColumn(id: col.id)
                } label: {
                    Label("Delete column", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .frame(width: airtableColWidth(col.type), alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
    }

    private func rowView(_ row: AirtableRow, index: Int) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                Text("#\(index + 1)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                Button {
                    store.moveAirtableRow(id: row.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Move up")
                Button {
                    store.moveAirtableRow(id: row.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Move down")
                Button {
                    store.deleteAirtableRow(id: row.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Delete row")
                Spacer()
            }
            .frame(width: 96, alignment: .leading)
            ForEach(columns) { col in
                cell(row: row, col: col)
            }
        }
        .padding(.vertical, 3)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.gray.opacity(0.08))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func cell(row: AirtableRow, col: AirtableColumn) -> some View {
        switch col.type {
        case .text, .number:
            AirtableTextField(rowID: row.id, columnID: col.id, numeric: col.type == .number, width: airtableColWidth(col.type))
                .environmentObject(store)
        case .checkbox:
            let checked = store.cellIsChecked(rowID: row.id, columnID: col.id)
            Button {
                store.setCellValue(rowID: row.id, columnID: col.id, checked ? "0" : "1")
            } label: {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16))
                    .foregroundStyle(checked ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .frame(width: airtableColWidth(col.type), height: 24, alignment: .leading)
        case .date:
            let binding = dateBinding(rowID: row.id, columnID: col.id)
            DatePicker("", selection: binding, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .frame(width: airtableColWidth(col.type), alignment: .leading)
                .padding(.horizontal, 8)
        }
    }

    private func dateBinding(rowID: Int, columnID: Int) -> Binding<Date> {
        Binding(
            get: {
                dateFromDay(store.cellValue(rowID: rowID, columnID: columnID)) ?? Date()
            },
            set: { newDate in
                store.setCellValue(rowID: rowID, columnID: columnID, dayString(newDate))
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tablecells")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            Text("No tables yet — your mini Airtable")
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

// MARK: - Cell text field (commits on submit / disappear)

struct AirtableTextField: View {
    @EnvironmentObject var store: Store
    let rowID: Int
    let columnID: Int
    let numeric: Bool
    let width: CGFloat

    @State private var text = ""

    var body: some View {
        TextField("", text: $text)
            .textFieldStyle(.plain)
            .font(.callout)
            .multilineTextAlignment(numeric ? .trailing : .leading)
            .padding(.horizontal, 8)
            .frame(width: width, height: 26)
            .background(.background.secondary.opacity(0.4), in: RoundedRectangle(cornerRadius: 5))
            .onSubmit { commit() }
            .onDisappear { commit() }
            .onAppear {
                if text.isEmpty {
                    text = store.cellValue(rowID: rowID, columnID: columnID)
                }
            }
    }

    private func commit() {
        let stored = store.cellValue(rowID: rowID, columnID: columnID)
        if text != stored {
            store.setCellValue(rowID: rowID, columnID: columnID, text)
        }
    }
}

// MARK: - Add column sheet

struct AirtableAddColumnSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, AirtableColType) -> Void

    @State private var name = ""
    @State private var type: AirtableColType = .text

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Column")
                .font(.title2.bold())
            TextField("Column name", text: $name)
                .textFieldStyle(.roundedBorder)
            Picker("Type", selection: $type) {
                ForEach(AirtableColType.allCases) { t in
                    Label(t.displayName, systemImage: t.symbol).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(name, type)
                    dismiss()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
