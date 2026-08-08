import SwiftUI
import AppKit

struct VoiceNotesView: View {
    @EnvironmentObject var store: Store
    @State private var searchText = ""
    @State private var editingNote: AudioNote?
    @State private var confirmingDelete: AudioNote?

    private var notes: [AudioNote] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.audioNotes }
        return store.audioNotes.filter { store.audioNote($0, matches: q) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.isRecordingAudio {
                recordingBanner
                Divider()
            }
            if notes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(notes) { note in
                        VoiceNoteRowView(
                            note: note,
                            isPlaying: store.nowPlayingAudioNoteID == note.id && store.isPlaying,
                            onPlay: { store.toggleAudioNotePlayback(id: note.id) },
                            onEdit: { editingNote = note },
                            onDelete: { confirmingDelete = note }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(item: $editingNote) { note in
            EditVoiceNoteView(note: note)
                .environmentObject(store)
        }
        .alert("Delete voice note?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let note = confirmingDelete {
                    store.deleteAudioNote(note.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text("The recording and its notes will be permanently removed.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Voice Notes")
                    .font(.title.bold())
                Text("\(store.audioNotes.count) recordings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            recordButton
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search voice notes…", text: $searchText)
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
        .frame(width: 230)
    }

    private var recordButton: some View {
        Button {
            store.startRecordingAudioNote()
        } label: {
            Label("Record", systemImage: "mic.fill")
        }
        .buttonStyle(.borderedProminent)
        .disabled(store.isRecordingAudio)
    }

    private var recordingBanner: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .opacity(store.recordingAudioTime.truncatingRemainder(dividingBy: 1) < 0.5 ? 1 : 0.3)
            Text("Recording…")
                .font(.subheadline.weight(.semibold))
            Text(timeString(store.recordingAudioTime))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                store.stopRecordingAudioNote()
            } label: {
                Label("Stop & Save", systemImage: "stop.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "mic")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(store.audioNotes.isEmpty ? "No voice notes yet — hit Record to capture your first one" : "No voice notes match your search")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func timeString(_ time: TimeInterval) -> String {
        let total = Int(time.rounded())
        let m = total / 60
        let s = total % 60
        return m > 0 ? "\(m):\(String(format: "%02d", s))" : "0:\(String(format: "%02d", s))"
    }
}

// MARK: - Row

private struct VoiceNoteRowView: View {
    let note: AudioNote
    let isPlaying: Bool
    let onPlay: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background((isPlaying ? Color.orange : Color.blue).gradient, in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.subheadline.weight(.semibold))
                if !note.notes.isEmpty {
                    Text(note.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text(note.durationText)
                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "stop.fill" : "arrow.counterclockwise")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            onEdit()
        }
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit

struct EditVoiceNoteView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let note: AudioNote
    @State private var title = ""
    @State private var notes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Voice Note")
                .font(.title2.bold())
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            Text("Notes")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            TextEditor(text: $notes)
                .font(.body)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(4)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    store.updateAudioNote(id: note.id, title: title, notes: notes)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
        .onAppear {
            title = note.title
            notes = note.notes
        }
    }
}
