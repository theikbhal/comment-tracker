import SwiftUI
import AppKit

struct TreeView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: TreeNode?
    @State private var confirmingDelete: TreeNode?
    @State private var addingChildTo: TreeNode?

    private var roots: [TreeNode] {
        var list = store.rootTreeNodes()
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            let matching = Set(store.treeNodes.filter { store.treeNode($0, matches: q) }.map { $0.id })
            var included: Set<Int> = []
            for id in matching {
                var current: Int? = id
                while let nodeID = current {
                    included.insert(nodeID)
                    current = store.treeNodes.first(where: { $0.id == nodeID })?.parentId
                }
            }
            list = list.filter { included.contains($0.id) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if roots.isEmpty {
                        Text("No branches yet. Plant a root and grow branches from it.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(roots) { node in
                        TreeNodeRow(node: node, depth: 0) { child in
                            addingChildTo = child
                        } onEdit: { child in
                            editing = child
                        } onDelete: { child in
                            confirmingDelete = child
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            TreeNodeEditSheet(title: "", note: "", prompt: "New branch") { title, note in
                store.addTreeNode(parentID: nil, title: title, note: note)
            }
        }
        .sheet(item: $addingChildTo) { parent in
            TreeNodeEditSheet(title: "", note: "", prompt: "Child of \(parent.title)") { title, note in
                store.addTreeNode(parentID: parent.id, title: title, note: note)
            }
        }
        .sheet(item: $editing) { node in
            TreeNodeEditSheet(title: node.title, note: node.note, prompt: "Edit branch") { title, note in
                store.updateTreeNode(id: node.id, title: title, note: note)
            }
        }
        .confirmationDialog("Delete this branch and everything under it?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let node = confirmingDelete {
                    store.deleteTreeNode(node.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mini Tree")
                    .font(.title.bold())
                Text("\(store.treeNodes.count) branches")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Root", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        TextField("Search", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .frame(width: 160)
    }
}

// MARK: - Node row (recursive)

struct TreeNodeRow: View {
    @EnvironmentObject var store: Store
    let node: TreeNode
    let depth: Int
    let onAddChild: (TreeNode) -> Void
    let onEdit: (TreeNode) -> Void
    let onDelete: (TreeNode) -> Void

    @State private var isExpanded = false

    private var children: [TreeNode] {
        store.treeChildren(of: node.id)
    }

    private var hasChildren: Bool {
        store.hasTreeChildren(node.id)
    }

    private var renderedNote: AttributedString? {
        let trimmed = node.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: hasChildren ? (isExpanded ? "chevron.down" : "chevron.right") : "leaf")
                        .font(.caption.bold())
                        .foregroundStyle(hasChildren ? Color.accentColor : Color.secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!hasChildren)

                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(.callout.weight(.semibold))
                    if let note = renderedNote {
                        Text(note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text("\(children.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Menu {
                    Button("Add Child") { onAddChild(node) }
                    Button("Edit") { onEdit(node) }
                    Button("Move Up") { store.moveTreeNode(id: node.id, direction: -1) }
                    Button("Move Down") { store.moveTreeNode(id: node.id, direction: 1) }
                    Button("Delete", role: .destructive) { onDelete(node) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.04))
            )

            if isExpanded && hasChildren {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(children) { child in
                        TreeNodeRow(node: child, depth: depth + 1) { child in
                            onAddChild(child)
                        } onEdit: { child in
                            onEdit(child)
                        } onDelete: { child in
                            onDelete(child)
                        }
                    }
                }
                .padding(.leading, 18)
            }
        }
    }
}

// MARK: - Edit sheet

struct TreeNodeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let note: String
    let prompt: String
    let onSave: (String, String) -> Void

    @State private var titleText: String
    @State private var noteText: String

    init(title: String, note: String, prompt: String, onSave: @escaping (String, String) -> Void) {
        self.title = title
        self.note = note
        self.prompt = prompt
        self.onSave = onSave
        _titleText = State(initialValue: title)
        _noteText = State(initialValue: note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(prompt)
                .font(.headline)
            TextField("Title", text: $titleText)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $noteText)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
            Text("Note — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(titleText, noteText)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
