import SwiftUI
import AppKit

struct CelebrationsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: Celebration?
    @State private var confirmingDelete: Celebration?
    @State private var opening: Celebration?

    private var celebrations: [Celebration] {
        var list = store.celebrations
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.celebration($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    overviewCard
                    if celebrations.isEmpty {
                        Text("No celebrations yet. Collect a video you want to remember and replay — wins, milestones, moments.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(celebrations) { celebration in
                        CelebrationCard(celebration: celebration) {
                            opening = celebration
                        } onEdit: {
                            editing = celebration
                        } onDelete: {
                            confirmingDelete = celebration
                        } onMoveUp: {
                            store.moveCelebration(id: celebration.id, direction: -1)
                        } onMoveDown: {
                            store.moveCelebration(id: celebration.id, direction: 1)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            CelebrationEditSheet { title, url in
                store.addCelebration(title: title, url: url)
            }
        }
        .sheet(item: $editing) { celebration in
            CelebrationEditSheet(title: celebration.title, url: celebration.url) { title, url in
                store.updateCelebration(id: celebration.id, title: title, url: url)
            }
        }
        .sheet(item: $opening) { celebration in
            CelebrationDetailSheet(celebration: celebration)
                .environmentObject(store)
        }
        .confirmationDialog("Delete this celebration and its comments?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let celebration = confirmingDelete {
                    store.deleteCelebration(celebration.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Celebrations")
                    .font(.title.bold())
                Text("\(store.celebrations.count) videos")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Video", systemImage: "plus")
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

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Celebrations overview", systemImage: "party.popper")
                .font(.headline)
            TextEditor(text: overviewText)
                .frame(height: 100)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if overviewText.wrappedValue.isEmpty {
                        Text("Notes about the whole collection — outside any single video…")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .allowsHitTesting(false)
                    }
                }
            HStack {
                Spacer()
                Button("Save Overview") {
                    store.saveCelebrationNotes(overviewText.wrappedValue)
                }
                .buttonStyle(.borderedProminent)
                .disabled(overviewText.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines) == store.celebrationNotes)
            }
        }
        .card()
    }

    private var overviewText: Binding<String> {
        Binding(
            get: { store.celebrationNotes },
            set: { store.celebrationNotes = $0 }
        )
    }
}

// MARK: - Card

struct CelebrationCard: View {
    @EnvironmentObject var store: Store
    let celebration: Celebration
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private var comments: [CelebrationComment] {
        store.celebrationComments(for: celebration.id)
    }

    private var youtubeID: String? {
        youtubeVideoID(from: celebration.url)
    }

    private var renderedNote: AttributedString? {
        let trimmed = celebration.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(spacing: 12) {
            if let id = youtubeID {
                YouTubeThumb(videoID: id)
                    .frame(width: 120, height: 68)
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 120, height: 68)
                    .overlay(
                        Image(systemName: "party.popper")
                            .foregroundStyle(.secondary)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(celebration.title)
                    .font(.headline)
                if let rendered = renderedNote {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Button {
                        onOpen()
                    } label: {
                        Label("Replay", systemImage: "play.circle.fill")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    Button {
                        onOpen()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 11))
                            Text("\(comments.count)")
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(comments.isEmpty ? Color.secondary : Color.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((comments.isEmpty ? Color.gray : Color.pink).opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .help("Comments")
                }
            }
            Spacer()
            Menu {
                Button("Open & Replay", action: onOpen)
                Button("Edit", action: onEdit)
                Button("Move Up", action: onMoveUp)
                Button("Move Down", action: onMoveDown)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onOpen() }
        .contextMenu {
            Button { onOpen() } label: {
                Label("Open & Replay", systemImage: "play.circle")
            }
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
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

// MARK: - Detail sheet (replay + video-level notes + comments)

struct CelebrationDetailSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let celebration: Celebration

    @State private var note = ""
    @State private var noteEdited = false
    @State private var newComment = ""

    private var comments: [CelebrationComment] {
        store.celebrationComments(for: celebration.id)
    }

    private var youtubeID: String? {
        youtubeVideoID(from: celebration.url)
    }

    private var renderedNote: AttributedString? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(celebration.title)
                    .font(.title2.bold())
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            if let id = youtubeID {
                YouTubeEmbedView(videoID: id)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if !celebration.url.isEmpty {
                HStack {
                    Text("Not a YouTube link.")
                        .font(.caption)
                    Button {
                        if let u = URL(string: celebration.url.hasPrefix("http") ? celebration.url : "https://\(celebration.url)") {
                            NSWorkspace.shared.open(u)
                        }
                    } label: {
                        Label("Open in browser", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.link)
                }
                .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Notes for this video", systemImage: "note.text")
                        .font(.headline)
                    Spacer()
                    if noteEdited {
                        Button("Save") {
                            store.updateCelebrationNote(id: celebration.id, note: note)
                            noteEdited = false
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                TextEditor(text: $note)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 90)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: note) { _ in
                        noteEdited = true
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

            Divider()

            commentsSection
        }
        .padding(20)
        .frame(width: 560, height: 680)
        .onAppear {
            note = celebration.note
            noteEdited = false
        }
    }

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Comments")
                    .font(.headline)
                Spacer()
                Text("\(comments.count)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                TextField("Add a comment…", text: $newComment)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        store.addCelebrationComment(celebrationID: celebration.id, body: newComment)
                        newComment = ""
                    }
                Button {
                    store.addCelebrationComment(celebrationID: celebration.id, body: newComment)
                    newComment = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ScrollView {
                VStack(spacing: 0) {
                    if comments.isEmpty {
                        Text("Nothing yet — share what this celebration means.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                            commentRow(comment)
                            if index < comments.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func commentRow(_ comment: CelebrationComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.body)
                    .font(.subheadline)
                Text(comment.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button {
                store.deleteCelebrationComment(comment.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete comment")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

// MARK: - Edit sheet

struct CelebrationEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String) -> Void

    @State private var title: String
    @State private var url: String

    init(title: String = "", url: String = "", onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _title = State(initialValue: title)
        _url = State(initialValue: url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.isEmpty ? "New Celebration" : "Edit Celebration")
                .font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Video link (YouTube…)", text: $url)
                .textFieldStyle(.roundedBorder)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(title, url)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
