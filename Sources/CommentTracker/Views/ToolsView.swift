import SwiftUI
import AppKit

struct ToolsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: Tool?
    @State private var confirmingDelete: Tool?

    private var tools: [Tool] {
        var list = store.sortedTools
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.tool($0, matches: searchText) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if tools.isEmpty {
                        Text("No tools yet. Add your first tool — name, a note, and a link.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(Array(tools.enumerated()), id: \.element.id) { index, tool in
                        ToolRow(tool: tool, isFirst: index == 0, isLast: index == tools.count - 1) {
                            editing = tool
                        } onDelete: {
                            confirmingDelete = tool
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            ToolEditSheet { name, note, link in
                store.addTool(name: name, note: note, link: link)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { tool in
            ToolEditSheet(
                existing: tool,
                onSave: { name, note, link in
                    store.updateTool(id: tool.id, name: name, note: note, link: link)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this tool?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let tool = confirmingDelete {
                    store.deleteTool(tool.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text(confirmingDelete.map { "This removes \"\($0.name)\" and its note." } ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tools")
                    .font(.title.bold())
                Text("\(store.tools.count) tools")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Tool", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search tools…", text: $searchText)
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

struct ToolRow: View {
    @EnvironmentObject var store: Store
    let tool: Tool
    let isFirst: Bool
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var renderedNote: AttributedString? {
        let trimmed = tool.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Button {
                    store.moveTool(id: tool.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isFirst)
                .opacity(isFirst ? 0.3 : 1)
                .help("Move up")
                Button {
                    store.moveTool(id: tool.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isLast)
                .opacity(isLast ? 0.3 : 1)
                .help("Move down")
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.indigo.gradient, in: RoundedRectangle(cornerRadius: 6))
                    Text(tool.name)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    if !tool.link.isEmpty {
                        Button {
                            if let url = URL(string: tool.link.hasPrefix("http") ? tool.link : "https://\(tool.link)") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label("Open", systemImage: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .help("Open \(tool.link)")
                    }
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Edit tool")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete tool")
                }
                if let rendered = renderedNote {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .onTapGesture(count: 2) { onEdit() }
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit tool…", systemImage: "pencil")
            }
            if !tool.link.isEmpty {
                Button {
                    if let url = URL(string: tool.link.hasPrefix("http") ? tool.link : "https://\(tool.link)") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open link", systemImage: "arrow.up.right.square")
                }
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

struct ToolEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: Tool? = nil
    let onSave: (String, String, String) -> Void

    @State private var name = ""
    @State private var link = ""
    @State private var note = ""

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Tool" : "Edit Tool")
                .font(.title2.bold())
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Link (optional) — youtube, URL…", text: $link)
                .textFieldStyle(.roundedBorder)
            Text("Note — markdown supported ([link](https://…), **bold**, lists)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 140)
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
                    onSave(name, note, link)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            if let existing {
                name = existing.name
                link = existing.link
                note = existing.note
            }
        }
    }
}
