import SwiftUI
import AppKit

struct StacksView: View {
    @EnvironmentObject var store: Store
    @State private var showingAddStack = false
    @State private var message = ""

    private var stacks: [Stack] {
        store.stacks.sorted { $0.position < $1.position }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(stacks) { stack in
                        StackColumnView(stack: stack)
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAddStack) {
            StackEditSheet { name, color in
                store.addStack(name: name, color: color)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Stacks")
                    .font(.title.bold())
                Text("\(stacks.count) stacks · \(store.stackItems.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Button {
                showingAddStack = true
            } label: {
                Label("Add Stack", systemImage: "plus.rectangle.on.rectangle")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }
}

// MARK: - Stack column

struct StackColumnView: View {
    @EnvironmentObject var store: Store
    let stack: Stack

    @State private var newItem = ""
    @State private var editingStack = false
    @State private var confirmingDelete = false
    @State private var confirmingPop = false
    @State private var selectedItem: StackItem?

    private var items: [StackItem] {
        store.items(in: stack.id)
    }

    private var isUncategorized: Bool {
        stack.name == "Uncategorized"
    }

    private var color: Color {
        stackColor(stack.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            pushField
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 5) {
                    ForEach(items) { item in
                        StackItemCell(stack: stack, item: item) {
                            selectedItem = item
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: .infinity)
            footer
        }
        .padding(10)
        .frame(width: 210, alignment: .leading)
        .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .sheet(item: $selectedItem) { item in
            StackItemDetailSheet(item: item, stack: stack)
        }
        .sheet(isPresented: $editingStack) {
            StackEditSheet(existing: stack) { name, color in
                store.updateStack(id: stack.id, name: name, color: color)
            }
        }
        .confirmationDialog("Delete this stack and its items?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteStack(stack.id)
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Pop the top item to Uncategorized?", isPresented: $confirmingPop, titleVisibility: .visible) {
            Button("Pop") {
                store.popTopItem(from: stack.id)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(stack.name)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text("\(items.count)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15), in: Capsule())
        }
        .contextMenu {
            Button {
                editingStack = true
            } label: {
                Label("Edit stack", systemImage: "pencil")
            }
            if !isUncategorized {
                Button("Move Left") {
                    store.moveStack(id: stack.id, direction: -1)
                }
                Button("Move Right") {
                    store.moveStack(id: stack.id, direction: 1)
                }
                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Delete stack", systemImage: "trash")
                }
            }
        }
    }

    private var pushField: some View {
        HStack(spacing: 6) {
            TextField("Push (max 3 words)…", text: $newItem)
                .textFieldStyle(.roundedBorder)
                .font(.caption)
                .onSubmit(push)
            Button {
                push()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            .buttonStyle(.borderless)
            .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if isUncategorized {
                Text("Popped items land here")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Button {
                    confirmingPop = true
                } label: {
                    Label("Pop", systemImage: "arrow.down.circle")
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .disabled(items.isEmpty)
                .help("Move top item to Uncategorized")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func push() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.pushStackItem(stackID: stack.id, title: trimmed)
        newItem = ""
    }
}

// MARK: - Item cell (compact, 1-3 words)

struct StackItemCell: View {
    @EnvironmentObject var store: Store
    let stack: Stack
    let item: StackItem
    let onOpen: () -> Void

    private var color: Color {
        stackColor(stack.color)
    }

    private var commentCount: Int {
        store.stackComments(for: item.id).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(item.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                    .textSelection(.enabled)
                Spacer()
            }
            HStack(spacing: 4) {
                if commentCount > 0 {
                    Label("\(commentCount)", systemImage: "bubble.left")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                if !item.linksList.isEmpty {
                    Image(systemName: "link")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button {
                        onOpen()
                    } label: {
                        Label("Open detail", systemImage: "rectangle.badge.plus")
                    }
                    Button(role: .destructive) {
                        store.deleteStackItem(item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onTapGesture(count: 2) {
            onOpen()
        }
        .help("Double-click to open")
    }
}

// MARK: - Detail sheet (Trello-style with comments)

struct StackItemDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: Store
    let item: StackItem
    let stack: Stack

    @State private var title = ""
    @State private var description = ""
    @State private var links = ""
    @State private var newComment = ""
    @State private var commentTexts: [Int: String] = [:]

    private var color: Color {
        stackColor(stack.color)
    }

    private var comments: [StackComment] {
        store.stackComments(for: item.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                TextField("Title (max 3 words)", text: $title)
                    .font(.title3.bold())
                    .textFieldStyle(.plain)
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

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Description")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $description)
                    .font(.system(.callout))
                    .frame(height: 90)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Links (one per line)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $links)
                    .font(.system(.caption, design: .monospaced))
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Comments (\(comments.count))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if comments.isEmpty {
                    Text("No comments yet.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(comments) { comment in
                                commentRow(comment)
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
                HStack(spacing: 8) {
                    TextField("Add a comment…", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addComment)
                    Button {
                        addComment()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.borderless)
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    save()
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
        .frame(width: 460)
        .onAppear {
            title = item.title
            description = item.description
            links = item.links
        }
    }

    private func commentRow(_ comment: StackComment) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(comment.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                    Spacer()
                    Button {
                        store.deleteStackComment(comment.id)
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete comment")
                }
                Text(comment.body)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
    }

    private func addComment() {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addStackComment(itemID: item.id, body: trimmed)
        newComment = ""
    }

    private func save() {
        store.updateStackItem(id: item.id, title: title, description: description, links: links)
    }
}

// MARK: - Stack edit sheet

struct StackEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: Stack? = nil
    let onSave: (String, String) -> Void

    @State private var name = ""
    @State private var color = "blue"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(existing == nil ? "Add Stack" : "Edit Stack")
                .font(.headline)
            TextField("Stack name", text: $name)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(stackColorOptions, id: \.self) { c in
                        Button {
                            color = c
                        } label: {
                            Circle()
                                .fill(stackColor(c))
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(color == c ? Color.primary : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    onSave(name, color)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 340)
        .onAppear {
            if let existing {
                name = existing.name
                color = existing.color
            }
        }
    }
}
