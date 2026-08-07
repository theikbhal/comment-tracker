import SwiftUI
import AppKit

struct FollowUpView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var showDone = false
    @State private var editing: FollowUp?
    @State private var confirmingDelete: FollowUp?

    private var items: [FollowUp] {
        var list = store.followUpsSorted(showDone)
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.followUp($0, matches: q) }
        }
        return list
    }

    private var openCount: Int { store.openFollowUps.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if items.isEmpty {
                        Text(showDone ? "Nothing here" : "Nothing to follow up on. Clear.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(items) { item in
                        FollowUpRow(item: item) {
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
            FollowUpEditSheet { title, note, date in
                store.addFollowUp(title: title, note: note, date: date)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { item in
            FollowUpEditSheet(
                existing: item,
                onSave: { title, note, date in
                    store.updateFollowUp(id: item.id, title: title, note: note, date: date)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this follow-up?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = confirmingDelete {
                    store.deleteFollowUp(item.id)
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
                Text("Follow-ups")
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
            .help("Toggle showing done follow-ups")
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
            TextField("Search follow-ups…", text: $searchText)
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

struct FollowUpRow: View {
    @EnvironmentObject var store: Store
    let item: FollowUp
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
                store.toggleFollowUpDone(item.id)
            } label: {
                Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.done ? Color.green : Color.secondary)
            }
            .buttonStyle(.borderless)
            .help(item.done ? "Mark as open" : "Mark done")

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .strikethrough(item.done, color: .secondary)
                        .opacity(item.done ? 0.55 : 1)
                    if item.hasDate && !item.done {
                        HStack(spacing: 4) {
                            Image(systemName: item.isOverdue ? "exclamationmark.circle.fill" : "calendar")
                                .font(.system(size: 10))
                            Text(item.dateText)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(item.isOverdue ? .red : (item.dateText == "Today" ? .orange : .secondary))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((item.isOverdue ? Color.red : Color.gray).opacity(0.12), in: Capsule())
                        .help(item.isOverdue ? "Overdue" : "Follow up by \(item.date)")
                    }
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
                    .help("Edit")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
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
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.done ? Color.green.opacity(0.35) : (item.isOverdue ? Color.red.opacity(0.4) : Color.gray.opacity(0.14)), lineWidth: 1)
        )
        .onTapGesture(count: 2) { if !item.done { onEdit() } }
        .contextMenu {
            Button {
                store.toggleFollowUpDone(item.id)
            } label: {
                Label(item.done ? "Mark as open" : "Mark done", systemImage: item.done ? "circle" : "checkmark.circle")
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

struct FollowUpEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: FollowUp? = nil
    let onSave: (String, String, String) -> Void

    @State private var title = ""
    @State private var note = ""
    @State private var hasDate = false
    @State private var date = Date()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Follow-up" : "Edit Follow-up")
                .font(.title2.bold())
            TextField("Follow up on what?", text: $title)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 10) {
                Toggle(isOn: $hasDate) {
                    Label("Date", systemImage: "calendar")
                        .font(.caption)
                        .fixedSize()
                }
                .toggleStyle(.checkbox)
                if hasDate {
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            Text("Note — markdown supported ([link](https://…), **bold**)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 100)
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
                    let d = hasDate ? Self.dayFormatter.string(from: date) : ""
                    onSave(title, note, d)
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
                if existing.hasDate, let d = dateFromDay(existing.date) {
                    hasDate = true
                    date = d
                }
            }
        }
    }
}
