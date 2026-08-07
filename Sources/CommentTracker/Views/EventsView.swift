import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct EventsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: EventShow?
    @State private var confirmingDelete: EventShow?
    @State private var expandedID: Int?
    @State private var audioPickerFor: EventShow?
    @State private var editingEpisode: EventEpisode?
    @State private var confirmingDeleteEpisode: EventEpisode?
    @State private var pickedAudio: PickedAudio?

    private struct PickedAudio: Identifiable {
        let id = UUID()
        let url: URL
        let eventID: Int
    }

    private var events: [EventShow] {
        var list = store.events
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.eventShow($0, matches: q) }
        }
        return list.sorted { lhs, rhs in
            if lhs.subscribed != rhs.subscribed { return lhs.subscribed }
            return lhs.position < rhs.position
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if store.nowPlayingEpisodeID != nil {
                Divider()
                nowPlayingBar
            }
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    if events.isEmpty {
                        Text("No events yet. Add something you follow — a show, a feed, a series — and subscribe.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(events) { event in
                        EventCard(
                            event: event,
                            isExpanded: expandedID == event.id,
                            onToggleExpand: {
                                expandedID = expandedID == event.id ? nil : event.id
                            },
                            onEdit: { editing = event },
                            onDelete: { confirmingDelete = event },
                            onToggleSubscribe: { store.toggleSubscribed(id: event.id) },
                            onMoveUp: { store.moveEvent(id: event.id, direction: -1) },
                            onMoveDown: { store.moveEvent(id: event.id, direction: 1) },
                            onPickAudio: { audioPickerFor = event },
                            onEditEpisode: { editingEpisode = $0 },
                            onDeleteEpisode: { confirmingDeleteEpisode = $0 }
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            EventEditSheet { title, description in
                store.addEvent(title: title, description: description)
            }
        }
        .sheet(item: $editing) { event in
            EventEditSheet(
                title: event.title,
                description: event.description
            ) { title, description in
                store.updateEvent(id: event.id, title: title, description: description)
            }
        }
        .sheet(item: $editingEpisode) { episode in
            EpisodeEditSheet(
                title: episode.title,
                note: episode.note,
                isNew: false
            ) { title, note in
                store.updateEpisode(id: episode.id, title: title, note: note)
            }
        }
        .sheet(item: $pickedAudio) { audio in
            EpisodeEditSheet(title: "", note: "", isNew: true) { title, note in
                store.addEpisode(eventID: audio.eventID, title: title, note: note, from: audio.url)
            }
        }
        .confirmationDialog("Delete this event and its episodes?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let event = confirmingDelete {
                    store.deleteEvent(event.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
        .confirmationDialog("Delete this episode?", isPresented: Binding(
            get: { confirmingDeleteEpisode != nil },
            set: { if !$0 { confirmingDeleteEpisode = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let episode = confirmingDeleteEpisode {
                    store.deleteEpisode(episode.id)
                }
                confirmingDeleteEpisode = nil
            }
            Button("Cancel", role: .cancel) { confirmingDeleteEpisode = nil }
        }
        .fileImporter(isPresented: Binding(
            get: { audioPickerFor != nil },
            set: { if !$0 { audioPickerFor = nil } }
        ), allowedContentTypes: [.audio], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first, let event = audioPickerFor {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let tmp = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + "." + url.pathExtension)
                do {
                    try FileManager.default.copyItem(at: url, to: tmp)
                    pickedAudio = PickedAudio(url: tmp, eventID: event.id)
                } catch {
                    return
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Events")
                    .font(.title.bold())
                Text("\(store.events.filter { $0.subscribed }.count) subscribed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Event", systemImage: "plus")
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

    private var nowPlayingBar: some View {
        HStack(spacing: 12) {
            Image(systemName: store.isPlaying ? "speaker.wave.2.fill" : "pause.circle.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(nowPlayingEpisodeTitle)
                    .font(.headline)
                Text(nowPlayingEventTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.togglePlayback()
            } label: {
                Image(systemName: store.isPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 20)
            }
            .buttonStyle(.bordered)
            Button {
                store.stopPlayback()
            } label: {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var nowPlayingEpisodeTitle: String {
        guard let id = store.nowPlayingEpisodeID,
              let episode = store.eventEpisodes.first(where: { $0.id == id }) else { return "Nothing playing" }
        return episode.title
    }

    private var nowPlayingEventTitle: String {
        guard let id = store.nowPlayingEventID,
              let event = store.events.first(where: { $0.id == id }) else { return "" }
        return event.title
    }
}

// MARK: - Event card

struct EventCard: View {
    @EnvironmentObject var store: Store
    let event: EventShow
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleSubscribe: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onPickAudio: () -> Void
    let onEditEpisode: (EventEpisode) -> Void
    let onDeleteEpisode: (EventEpisode) -> Void

    private var episodes: [EventEpisode] {
        store.episodes(for: event.id)
    }

    private var renderedDescription: AttributedString? {
        let trimmed = event.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    onToggleExpand()
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.headline)
                    Text("\(episodes.count) episode\(episodes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onToggleSubscribe()
                } label: {
                Image(systemName: event.subscribed ? "bell.fill" : "bell.slash")
                    .foregroundStyle(event.subscribed ? Color.accentColor : .secondary)
                }
                .buttonStyle(.borderless)
                .help(event.subscribed ? "Unsubscribe" : "Subscribe")
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Move Up", action: onMoveUp)
                    Button("Move Down", action: onMoveDown)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }

            if isExpanded {
                if let description = renderedDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                if episodes.isEmpty {
                    Text("No episodes yet. Add your first audio episode.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(episodes) { episode in
                            EpisodeRow(
                                episode: episode,
                                isNowPlaying: store.nowPlayingEpisodeID == episode.id,
                                isPlaying: store.isPlaying,
                                onPlay: { store.playEpisode(eventID: event.id, episodeID: episode.id) },
                                onTogglePlayback: { store.togglePlayback() },
                                onStop: { store.stopPlayback() },
                                onEdit: { onEditEpisode(episode) },
                                onDelete: { onDeleteEpisode(episode) }
                            )
                        }
                    }
                }

                Button {
                    onPickAudio()
                } label: {
                    Label("Add Episode", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .card()
    }
}

// MARK: - Episode row

struct EpisodeRow: View {
    let episode: EventEpisode
    let isNowPlaying: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onTogglePlayback: () -> Void
    let onStop: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var renderedNote: AttributedString? {
        let trimmed = episode.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if isNowPlaying {
                    onTogglePlayback()
                } else {
                    onPlay()
                }
            } label: {
                Image(systemName: isNowPlaying ? (isPlaying ? "pause.fill" : "play.fill") : "play.fill")
                    .frame(width: 16)
            }
            .buttonStyle(.bordered)
            .help(isNowPlaying ? (isPlaying ? "Pause" : "Resume") : "Listen")

            if isNowPlaying {
                Button {
                    onStop()
                } label: {
                    Image(systemName: "stop.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.callout.weight(.semibold))
                if let note = renderedNote {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Text(episode.durationText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNowPlaying ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Edit sheets

struct EventEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let description: String
    let onSave: (String, String) -> Void

    @State private var titleText: String
    @State private var descriptionText: String

    init(title: String = "", description: String = "", onSave: @escaping (String, String) -> Void) {
        self.title = title
        self.description = description
        self.onSave = onSave
        _titleText = State(initialValue: title)
        _descriptionText = State(initialValue: description)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.isEmpty ? "New Event" : "Edit Event")
                .font(.headline)
            TextField("Title", text: $titleText)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $descriptionText)
                .frame(height: 100)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
            Text("Description — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(titleText, descriptionText)
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

struct EpisodeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let note: String
    let isNew: Bool
    let onSave: (String, String) -> Void

    @State private var titleText: String
    @State private var noteText: String

    init(title: String, note: String, isNew: Bool, onSave: @escaping (String, String) -> Void) {
        self.title = title
        self.note = note
        self.isNew = isNew
        self.onSave = onSave
        _titleText = State(initialValue: title)
        _noteText = State(initialValue: note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isNew ? "New Episode" : "Edit Episode")
                .font(.headline)
            if isNew {
                Text("Audio selected — enter a title and notes for the episode.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
            }
        }
        .padding(16)
        .frame(width: 380)
    }
}
