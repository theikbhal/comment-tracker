import SwiftUI
import AppKit

private let notesPageSize = 20

private func noteTimeAgo(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "now" }
    if interval < 3600 { return "\(Int(interval / 60))m" }
    if interval < 86400 { return "\(Int(interval / 3600))h" }
    if interval < 7 * 86400 { return "\(Int(interval / 86400))d" }
    return date.formatted(date: .numeric, time: .omitted)
}

struct InterstitialNotesView: View {
    @EnvironmentObject var store: Store
    @State private var draft = ""
    @State private var searchText = ""
    @State private var onlyBookmarked = false
    @State private var loaded = notesPageSize
    @State private var editing: InterNote?

    private var allNotes: [InterNote] {
        var list = store.interNotes
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { store.interNote($0, matches: searchText) }
        }
        if onlyBookmarked {
            list = list.filter(\.bookmarked)
        }
        return list
    }

    private var shownNotes: [InterNote] { Array(allNotes.prefix(loaded)) }

    private var canLoadMore: Bool { loaded < allNotes.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    composeBox
                    ForEach(shownNotes) { note in
                        NoteCardView(note: note) {
                            editing = note
                        }
                    }
                    if allNotes.isEmpty {
                        emptyState
                    } else if canLoadMore {
                        Button {
                            loaded += notesPageSize
                        } label: {
                            Text("Show older notes")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .padding(.horizontal, 16)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20)
                .frame(maxWidth: 620, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(item: $editing) { note in
            EditNoteSheet(note: note) { newText in
                store.updateInterNote(note.id, text: newText)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Notes")
                    .font(.title.bold())
                Text("\(store.interNotes.count) check-ins logged")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                onlyBookmarked.toggle()
                loaded = notesPageSize
            } label: {
                Label("Bookmarked", systemImage: onlyBookmarked ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(onlyBookmarked ? .yellow : .secondary)
            .help("Show only bookmarked notes")
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search notes…", text: $searchText)
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

    private var composeBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.indigo.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 54)
                        .overlay(alignment: .topLeading) {
                            if draft.isEmpty {
                                Text("Pause and write what you're doing right now…")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 7)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                    HStack {
                        Text("\(draft.count)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        Spacer()
                        Button {
                            store.addInterNote(draft)
                            draft = ""
                        } label: {
                            Label("Log note", systemImage: "note.text.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(onlyBookmarked ? "No bookmarked notes yet" : "No notes yet — log your first check-in above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Note card

struct NoteCardView: View {
    @EnvironmentObject var store: Store
    let note: InterNote
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "note.text")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.indigo.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Note")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.indigo)
                        Text(noteTimeAgo(note.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(note.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack(spacing: 12) {
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    store.moveInterNoteToTop(note.id)
                } label: {
                    Image(systemName: "arrow.up.to.line")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Move to top")
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Edit note")
                Button {
                    store.toggleInterNoteBookmark(note.id)
                } label: {
                    Image(systemName: note.bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                        .foregroundStyle(note.bookmarked ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(note.bookmarked ? "Remove bookmark" : "Bookmark this note")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(note.bookmarked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button {
                store.moveInterNoteToTop(note.id)
            } label: {
                Label("Move to top", systemImage: "arrow.up.to.line")
            }
            Button {
                onEdit()
            } label: {
                Label("Edit note…", systemImage: "pencil")
            }
            Button {
                store.toggleInterNoteBookmark(note.id)
            } label: {
                Label(note.bookmarked ? "Remove bookmark" : "Bookmark", systemImage: note.bookmarked ? "bookmark.slash" : "bookmark")
            }
            Divider()
            Button(role: .destructive) {
                store.deleteInterNote(note.id)
            } label: {
                Label("Delete note", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit sheet

struct EditNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    let note: InterNote
    let onSave: (String) -> Void

    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit Note")
                .font(.title2.bold())
            TextEditor(text: $text)
                .font(.body)
                .frame(minHeight: 120)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(text)
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
        .onAppear { text = note.text }
    }
}
