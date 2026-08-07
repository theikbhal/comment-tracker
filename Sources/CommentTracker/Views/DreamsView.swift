import SwiftUI
import AppKit

struct DreamsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: Dream?
    @State private var confirmingDelete: Dream?

    private var dreams: [Dream] {
        var list = store.sortedDreams
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.dream($0, matches: searchText) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if dreams.isEmpty {
                        Text("No dreams yet. Add one — a hope, an old ambition, something you once wanted.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(Array(dreams.enumerated()), id: \.element.id) { index, dream in
                        DreamRow(dream: dream, isFirst: index == 0, isLast: index == dreams.count - 1) {
                            editing = dream
                        } onDelete: {
                            confirmingDelete = dream
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            DreamEditSheet { title, note, link in
                store.addDream(title: title, note: note, link: link)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { dream in
            DreamEditSheet(
                existing: dream,
                onSave: { title, note, link in
                    store.updateDream(id: dream.id, title: title, note: note, link: link)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this dream?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let dream = confirmingDelete {
                    store.deleteDream(dream.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text(confirmingDelete.map { "This removes \"\($0.title)\" and its note." } ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Old Dreams")
                    .font(.title.bold())
                Text("\(store.dreams.count) dreams")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Dream", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search dreams…", text: $searchText)
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

struct DreamRow: View {
    @EnvironmentObject var store: Store
    let dream: Dream
    let isFirst: Bool
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var renderedNote: AttributedString? {
        let trimmed = dream.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Button {
                    store.moveDream(id: dream.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isFirst)
                .opacity(isFirst ? 0.3 : 1)
                .help("Move up")
                Button {
                    store.moveDream(id: dream.id, direction: 1)
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
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.purple.gradient, in: RoundedRectangle(cornerRadius: 6))
                    Text(dream.title)
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    if !dream.link.isEmpty {
                        Button {
                            if let url = URL(string: dream.link.hasPrefix("http") ? dream.link : "https://\(dream.link)") {
                                NSWorkspace.shared.open(url)
                            }
                        } label: {
                            Label("Open", systemImage: "arrow.up.right.square")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .help("Open \(dream.link)")
                    }
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Edit dream")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete dream")
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
                Label("Edit dream…", systemImage: "pencil")
            }
            if !dream.link.isEmpty {
                Button {
                    if let url = URL(string: dream.link.hasPrefix("http") ? dream.link : "https://\(dream.link)") {
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

struct DreamEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: Dream? = nil
    let onSave: (String, String, String) -> Void

    @State private var title = ""
    @State private var link = ""
    @State private var note = ""

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Dream" : "Edit Dream")
                .font(.title2.bold())
            TextField("Title", text: $title)
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
                    onSave(title, note, link)
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
                link = existing.link
                note = existing.note
            }
        }
    }
}
