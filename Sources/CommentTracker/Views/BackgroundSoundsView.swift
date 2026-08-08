import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AVFoundation

struct BackgroundSoundsView: View {
    @EnvironmentObject var store: Store
    @State private var searchText = ""
    @State private var showingAdd = false
    @State private var editing: BackgroundSound?
    @State private var confirmingDelete: BackgroundSound?
    @State private var pickingFile = false
    @State private var fileTarget: BackgroundSound?

    private var sounds: [BackgroundSound] {
        var list = store.backgroundSounds
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.backgroundSound($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.bgCurrentSoundID != nil {
                nowPlayingBar
                Divider()
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    presetsRow
                    if sounds.isEmpty {
                        Text("No background sounds yet. Pick a preset below or add your own link / local file.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(sounds) { sound in
                                BackgroundSoundRow(
                                    sound: sound,
                                    isNowPlaying: store.bgCurrentSoundID == sound.id,
                                    isPlaying: store.bgIsPlaying,
                                    onPlay: { store.playBackgroundSound(sound) },
                                    onToggle: { store.toggleBackgroundPlayback() },
                                    onStop: { store.stopBackgroundPlayback() },
                                    onEdit: { editing = sound },
                                    onDelete: { confirmingDelete = sound },
                                    onMoveUp: { store.moveBackgroundSound(id: sound.id, direction: -1) },
                                    onMoveDown: { store.moveBackgroundSound(id: sound.id, direction: 1) },
                                    onPickFile: { fileTarget = sound }
                                )
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 760, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            BackgroundSoundEditSheet { name, kind, value, note in
                store.addBackgroundSound(name: name, kind: kind, value: value, note: note)
            }
        }
        .sheet(item: $editing) { sound in
            BackgroundSoundEditSheet(
                name: sound.name,
                kind: sound.kind,
                value: sound.value,
                note: sound.note
            ) { name, kind, value, note in
                store.updateBackgroundSound(id: sound.id, name: name, kind: kind, value: value, note: note)
            }
        }
        .sheet(item: $fileTarget) { sound in
            BackgroundSoundEditSheet(
                name: sound.name,
                kind: .path,
                value: sound.value,
                note: sound.note
            ) { name, kind, value, note in
                store.updateBackgroundSound(id: sound.id, name: name, kind: kind, value: value, note: note)
            }
        }
        .confirmationDialog("Delete this background sound?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let sound = confirmingDelete {
                    store.deleteBackgroundSound(sound.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Background Sounds")
                    .font(.title.bold())
                Text("\(sounds.count) sounds · loops while you work across all tabs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Sound", systemImage: "plus")
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
            Image(systemName: store.bgIsPlaying ? "speaker.wave.2.fill" : "pause.circle.fill")
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(store.bgCurrentSound?.name ?? "Background")
                    .font(.headline)
                Text(store.bgCurrentSound?.note.isEmpty == false ? store.bgCurrentSound!.note : "Looping background")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                store.toggleBackgroundPlayback()
            } label: {
                Image(systemName: store.bgIsPlaying ? "pause.fill" : "play.fill")
                    .frame(width: 20)
            }
            .buttonStyle(.bordered)
            Button {
                store.stopBackgroundPlayback()
            } label: {
                Image(systemName: "stop.fill")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var presetsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick presets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: Array(repeating: GridItem(.adaptive(minimum: 140), spacing: 8), count: 4), spacing: 8) {
                ForEach(backgroundPresetNames, id: \.self) { name in
                    presetButton(name)
                }
            }
        }
    }

    private func presetButton(_ name: String) -> some View {
        let existing = store.bgPresetExists(name)
        return Button {
            if let sound = existing {
                store.playBackgroundSound(sound)
            } else {
                showingAdd = true
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "speaker.wave.2")
                    .font(.caption)
                Text(name)
                    .font(.caption.weight(.semibold))
                if existing == nil {
                    Text("+")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(existing != nil ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(existing != nil ? Color.accentColor.opacity(0.4) : Color.gray.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help(existing != nil ? "Play \(name)" : "Set up \(name) — add a link or file")
    }
}

// MARK: - Row

struct BackgroundSoundRow: View {
    @EnvironmentObject var store: Store
    let sound: BackgroundSound
    let isNowPlaying: Bool
    let isPlaying: Bool
    let onPlay: () -> Void
    let onToggle: () -> Void
    let onStop: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onPickFile: () -> Void

    private var kindLabel: String {
        switch sound.kind {
        case .link: return "Link"
        case .path: return "Local file"
        case .youtube: return "YouTube"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Button {
                if isNowPlaying {
                    onToggle()
                } else {
                    onPlay()
                }
            } label: {
                Image(systemName: isNowPlaying ? (isPlaying ? "pause.fill" : "play.fill") : "play.fill")
                    .frame(width: 16)
            }
            .buttonStyle(.bordered)
            .help(isNowPlaying ? (isPlaying ? "Pause" : "Resume") : "Play background")

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
                Text(sound.name)
                    .font(.callout.weight(.semibold))
                Text(sound.note.isEmpty ? kindLabel : "\(kindLabel) · \(sound.note)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            if sound.kind == .youtube, let id = youtubeVideoID(from: sound.value) {
                YouTubeThumb(videoID: id)
                    .frame(width: 80, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            Menu {
                Button("Edit", action: onEdit)
                if sound.kind == .link || sound.kind == .youtube {
                    Button("Choose local file instead") {
                        onPickFile()
                    }
                }
                Button("Move Up", action: onMoveUp)
                Button("Move Down", action: onMoveDown)
                Button("Delete", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
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

// MARK: - Edit sheet

struct BackgroundSoundEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, BackgroundSoundKind, String, String) -> Void

    @State private var name: String
    @State private var kind: BackgroundSoundKind
    @State private var value: String
    @State private var note: String
    @State private var pickingFile = false

    init(name: String = "", kind: BackgroundSoundKind = .link, value: String = "", note: String = "", onSave: @escaping (String, BackgroundSoundKind, String, String) -> Void) {
        self.onSave = onSave
        _name = State(initialValue: name)
        _kind = State(initialValue: kind)
        _value = State(initialValue: value)
        _note = State(initialValue: note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name.isEmpty ? "New Background Sound" : "Edit Background Sound")
                .font(.headline)
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            Picker("Type", selection: $kind) {
                ForEach(BackgroundSoundKind.allCases) { k in
                    Text(k.label).tag(k)
                }
            }
            .pickerStyle(.segmented)

            if kind == .path {
                HStack(spacing: 8) {
                    TextField("Local file path…", text: $value)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.caption, design: .monospaced))
                    Button {
                        pickingFile = true
                    } label: {
                        Label("Choose", systemImage: "folder")
                    }
                    .buttonStyle(.bordered)
                }
            } else if kind == .youtube {
                TextField("YouTube / Short / Reel URL…", text: $value)
                    .textFieldStyle(.roundedBorder)
                Text("Paste any YouTube link, Short, or IG reel. You can also just use a direct audio URL.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                TextField("Audio / video URL…", text: $value)
                    .textFieldStyle(.roundedBorder)
                Text("Any direct media link (mp3, m4a, mp4, stream URL) — loops continuously.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            TextEditor(text: $note)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
            Text("Note for this background (optional)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    onSave(name, kind, value.trimmingCharacters(in: .whitespacesAndNewlines), note)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 440)
        .fileImporter(isPresented: $pickingFile, allowedContentTypes: [.audio, .movie, .mpeg4Movie, .audiovisualContent], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                value = url.path
            }
        }
    }
}
