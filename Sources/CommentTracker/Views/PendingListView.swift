import SwiftUI
import AppKit

struct PendingListView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var showDone = false
    @State private var editing: PendingItem?
    @State private var confirmingDelete: PendingItem?

    private var pendingItems: [PendingItem] {
        var list = store.pendingItems.sorted { $0.position < $1.position }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.pendingItem($0, matches: q) }
        }
        if !showDone {
            list = list.filter { !$0.done }
        }
        return list
    }

    private var openCount: Int { store.pendingItems.filter { !$0.done }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if pendingItems.isEmpty {
                        Text(showDone ? "Nothing here" : "Nothing pending — clear mind, ready for what's next.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(Array(pendingItems.enumerated()), id: \.element.id) { index, item in
                        PendingRow(item: item, isFirst: index == 0, isLast: index == pendingItems.count - 1) {
                            editing = item
                        } onDelete: {
                            confirmingDelete = item
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            PendingEditSheet { title, note in
                store.addPendingItem(title: title, note: note)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { item in
            PendingEditSheet(
                existing: item,
                onSave: { title, note in
                    store.updatePendingItem(id: item.id, title: title, note: note)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this item?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = confirmingDelete {
                    store.deletePendingItem(item.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text(confirmingDelete.map { "This removes \"\($0.title)\"." } ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Pending")
                    .font(.title.bold())
                Text("\(openCount) open")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showDone.toggle()
            } label: {
                Label("Done", systemImage: showDone ? "checkmark.circle.fill" : "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(showDone ? .green : .secondary)
            .help("Toggle showing done items")
            Button {
                showingAdd = true
            } label: {
                Label("Add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search pending…", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .frame(width: 220)
    }
}

// MARK: - Row

struct PendingRow: View {
    @EnvironmentObject var store: Store
    let item: PendingItem
    let isFirst: Bool
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var renderedNote: AttributedString? {
        let trimmed = item.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                store.togglePendingItemDone(item.id)
            } label: {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.done ? Color.green : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(item.done ? "Mark as pending" : "Mark done")

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(item.done, color: .secondary)
                        .opacity(item.done ? 0.55 : 1)
                    Spacer()
                    Text(item.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Edit item")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete item")
                }
                if let rendered = renderedNote {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .opacity(item.done ? 0.6 : 1)
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
            }

            VStack(spacing: 4) {
                Button {
                    store.movePendingItem(id: item.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isFirst || item.done)
                .opacity((isFirst || item.done) ? 0.3 : 1)
                .help("Move up")
                Button {
                    store.movePendingItem(id: item.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isLast || item.done)
                .opacity((isLast || item.done) ? 0.3 : 1)
                .help("Move down")
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.done ? Color.green.opacity(0.35) : Color.gray.opacity(0.14), lineWidth: 1)
        )
        .onTapGesture(count: 2) { if !item.done { onEdit() } }
        .contextMenu {
            Button {
                store.togglePendingItemDone(item.id)
            } label: {
                Label(item.done ? "Mark as pending" : "Mark done", systemImage: item.done ? "circle" : "checkmark.circle")
            }
            Button { onEdit() } label: {
                Label("Edit…", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit sheet

struct PendingEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: PendingItem? = nil
    let onSave: (String, String) -> Void

    @State private var title = ""
    @State private var note = ""

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add to Pending" : "Edit Pending")
                .font(.title2.bold())
            TextField("What's pending?", text: $title)
                .textFieldStyle(.roundedBorder)
            Text("Note — markdown supported ([link](https://…), **bold**)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 120)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            if let rendered = renderedNote, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(rendered)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(title, note)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            if let existing {
                title = existing.title
                note = existing.note
            }
        }
    }
}
