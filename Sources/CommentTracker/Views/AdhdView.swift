import SwiftUI
import AppKit

struct AdhdView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(alignment: .top, spacing: 12) {
                ForEach(TriageAction.allCases) { action in
                    TriageColumn(action: action)
                }
            }
            .padding(16)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Task Triage")
                    .font(.title.bold())
                Text("\(store.adhdTriage.count) items — sort them so you stop getting stuck")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Button {
                store.addAdhdTriageItem(title: "Distraction I want to check", action: .decide)
            } label: {
                Label("Quick capture", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .help("Add a blank 'Decide later' item to dump a thought fast")
        }
        .padding(16)
    }
}

// MARK: - Column

struct TriageColumn: View {
    @EnvironmentObject var store: Store
    let action: TriageAction

    @State private var newTitle = ""
    @State private var editingItem: AdhdTriageItem?

    private var items: [AdhdTriageItem] {
        store.triageItems(in: action)
    }

    private var color: Color {
        action.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: action.symbol)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(action.shortLabel)
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15), in: Capsule())
            }
            .padding(.horizontal, 2)

            if action == .doit || action == .decide {
                quickAddField
            }

            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 6) {
                    ForEach(items) { item in
                        TriageRow(item: item, action: action, color: color) {
                            editingItem = item
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .sheet(item: $editingItem) { item in
            TriageEditSheet(item: item, action: action)
        }
    }

    private var quickAddField: some View {
        HStack(spacing: 6) {
            TextField("Add…", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .onSubmit(add)
            Button {
                add()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }
            .buttonStyle(.borderless)
            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func add() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addAdhdTriageItem(title: trimmed, action: action)
        newTitle = ""
    }
}

// MARK: - Row

struct TriageRow: View {
    @EnvironmentObject var store: Store
    let item: AdhdTriageItem
    let action: TriageAction
    let color: Color
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .textSelection(.enabled)
                Spacer()
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    moveMenu
                    Button(role: .destructive) {
                        store.deleteAdhdTriageItem(item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            if !item.note.isEmpty {
                Text(item.note)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onTapGesture(count: 2) {
            onEdit()
        }
        .help("Double-click to edit")
    }

    @ViewBuilder
    private var moveMenu: some View {
        ForEach(TriageAction.allCases.filter { $0 != action }) { target in
            Button {
                store.moveAdhdTriageItem(id: item.id, to: target)
            } label: {
                Label("Move to \(target.shortLabel)", systemImage: target.symbol)
            }
        }
        Button("Move Up") {
            store.reorderAdhdTriageItem(id: item.id, in: action, direction: -1)
        }
        Button("Move Down") {
            store.reorderAdhdTriageItem(id: item.id, in: action, direction: 1)
        }
    }
}

// MARK: - Edit sheet

struct TriageEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: Store
    let item: AdhdTriageItem
    let action: TriageAction

    @State private var title = ""
    @State private var note = ""
    @State private var target: TriageAction

    init(item: AdhdTriageItem, action: TriageAction) {
        self.item = item
        self.action = action
        _title = State(initialValue: item.title)
        _note = State(initialValue: item.note)
        _target = State(initialValue: item.action)
    }

    private var color: Color {
        target.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Edit Task")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $note)
                .frame(height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
            Text("Note — context, why, anything")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(TriageAction.allCases) { t in
                    Button {
                        target = t
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: t.symbol)
                            Text(t.shortLabel)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(target == t ? t.color.opacity(0.25) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(target == t ? t.color : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.updateAdhdTriageItem(id: item.id, title: trimmed, note: note)
                    if target != item.action {
                        store.moveAdhdTriageItem(id: item.id, to: target)
                    }
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18)
        .frame(width: 420)
    }
}
