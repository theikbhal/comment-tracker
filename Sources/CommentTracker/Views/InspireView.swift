import SwiftUI
import AppKit

struct InspireView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var onlyBookmarked = false
    @State private var editing: Inspiration?
    @State private var confirmingDelete: Inspiration?

    private var items: [Inspiration] {
        var list = store.sortedInspirations
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.inspiration($0, matches: q) }
        }
        if onlyBookmarked {
            list = list.filter(\.bookmarked)
        }
        return list
    }

    private var bookmarkedCount: Int { store.inspirations.filter(\.bookmarked).count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if items.isEmpty {
                        Text(onlyBookmarked ? "No bookmarked inspiration yet" : "Nothing here yet — capture what lifts you.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(items) { item in
                        InspireRow(item: item) {
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
            InspireEditSheet { text, source, note, link in
                store.addInspiration(text: text, source: source, note: note, link: link)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { item in
            InspireEditSheet(
                existing: item,
                onSave: { text, source, note, link in
                    store.updateInspiration(id: item.id, text: text, source: source, note: note, link: link)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this inspiration?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = confirmingDelete {
                    store.deleteInspiration(item.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text(confirmingDelete.map { "This removes \"\($0.text)\"." } ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Inspire")
                    .font(.title.bold())
                Text("\(store.inspirations.count) pieces · \(bookmarkedCount) bookmarked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                onlyBookmarked.toggle()
            } label: {
                Label("Bookmarked", systemImage: onlyBookmarked ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(onlyBookmarked ? .yellow : .secondary)
            .help("Show only bookmarked")
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
            TextField("Search inspiration…", text: $searchText)
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
        .frame(width: 200)
    }
}

// MARK: - Row

struct InspireRow: View {
    @EnvironmentObject var store: Store
    let item: Inspiration
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var renderedNote: AttributedString? {
        let trimmed = item.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.secondary)
                Text(item.text)
                    .font(.body.italic().weight(.medium))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                if !item.source.isEmpty {
                    Text("— \(item.source)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !item.link.isEmpty {
                    Button {
                        if let url = URL(string: item.link.hasPrefix("http") ? item.link : "https://\(item.link)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Open link")
                }
                Button {
                    store.moveInspiration(id: item.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Move up")
                Button {
                    store.moveInspiration(id: item.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .help("Move down")
                Button {
                    store.toggleInspirationBookmark(item.id)
                } label: {
                    Image(systemName: item.bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 12))
                        .foregroundStyle(item.bookmarked ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(item.bookmarked ? "Remove bookmark" : "Bookmark")
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
                    .environment(\.openURL, OpenURLAction { url in
                        NSWorkspace.shared.open(url)
                        return .handled
                    })
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.bookmarked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.14), lineWidth: 1)
        )
        .onTapGesture(count: 2) { onEdit() }
        .contextMenu {
            Button {
                store.toggleInspirationBookmark(item.id)
            } label: {
                Label(item.bookmarked ? "Remove bookmark" : "Bookmark", systemImage: item.bookmarked ? "bookmark.slash" : "bookmark")
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

struct InspireEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: Inspiration? = nil
    let onSave: (String, String, String, String) -> Void

    @State private var text = ""
    @State private var source = ""
    @State private var link = ""
    @State private var note = ""

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Inspiration" : "Edit Inspiration")
                .font(.title2.bold())
            TextEditor(text: $text)
                .font(.body.italic())
                .frame(minHeight: 70)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("The words that move you…")
                            .font(.body.italic())
                            .foregroundStyle(.tertiary)
                            .padding(.top, 12)
                            .padding(.leading, 12)
                            .allowsHitTesting(false)
                    }
                }
            TextField("Source (e.g. Rumi, a book)", text: $source)
                .textFieldStyle(.roundedBorder)
            TextField("Link (optional)", text: $link)
                .textFieldStyle(.roundedBorder)
            Text("Note — markdown supported ([link](https://…), **bold**)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 80)
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
                    onSave(text, source, note, link)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            if let existing {
                text = existing.text
                source = existing.source
                note = existing.note
                link = existing.link
            }
        }
    }
}
