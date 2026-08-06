import SwiftUI
import AppKit

struct VideoDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let videoID: Int

    @State private var title = ""
    @State private var note = ""
    @State private var descriptionText = ""
    @State private var url = ""
    @State private var newComment = ""

    private var video: Video? { store.videoByID(videoID) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    fieldsSection
                    commentsSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 620)
        .onAppear(perform: loadFields)
        .onChange(of: store.videos) {
            loadFields()
        }
    }

    private func loadFields() {
        guard let v = video else { return }
        title = v.title
        note = v.note
        descriptionText = v.description
        url = v.url
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            if let v = video {
                Image(systemName: v.platform.symbol)
                    .font(.system(size: 30))
                    .foregroundStyle(v.platform.color.gradient)
            }
            VStack(alignment: .leading, spacing: 2) {
                TextField("Title", text: $title)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                    .onSubmit { saveFields() }
                Text("Updated \(video?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let v = video {
                Picker("List", selection: Binding(
                    get: { v.stage },
                    set: { store.updateVideo(id: videoID, stage: $0) }
                )) {
                    ForEach(VideoStage.allCases) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                .labelsHidden()
                .frame(width: 150)
            }
        }
        .padding(16)
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Platform & link", systemImage: "play.rectangle")
                    .font(.headline)
                HStack(spacing: 8) {
                    if let v = video {
                        Picker("Platform", selection: Binding(
                            get: { v.platform },
                            set: { store.updateVideo(id: videoID, platform: $0) }
                        )) {
                            ForEach(VideoPlatform.allCases) { p in
                                Text(p.displayName).tag(p)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                    }
                    TextField("https://youtube.com/watch?v=…", text: $url)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { saveFields() }
                    if let v = video, let u = URL(string: v.url), !v.url.isEmpty {
                        Button {
                            NSWorkspace.shared.open(u)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(v.platform.color)
                        .help("Open video")
                    }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Label("Note", systemImage: "text.alignleft")
                    .font(.headline)
                TextField("Why save it — key takeaway", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveFields() }
            }
            VStack(alignment: .leading, spacing: 4) {
                Label("Description", systemImage: "doc.text")
                    .font(.headline)
                TextEditor(text: $descriptionText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 90)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
                HStack {
                    Text("Save edits automatically")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button("Save") { saveFields() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func saveFields() {
        store.updateVideo(id: videoID, title: title, note: note, description: descriptionText, url: url)
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Comments", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)

            if store.videoComments(for: videoID).isEmpty {
                Text("Nothing yet — notes, timestamps, takeaways.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.videoComments(for: videoID).enumerated()), id: \.element.id) { index, comment in
                        commentRow(comment)
                        if index < store.videoComments(for: videoID).count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextEditor(text: $newComment)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 56)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if newComment.isEmpty {
                            Text("Write a comment…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                                .allowsHitTesting(false)
                        }
                    }
                Button {
                    store.addVideoComment(videoID: videoID, body: newComment)
                    newComment = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                }
                .buttonStyle(.borderless)
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func commentRow(_ comment: VideoComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "film")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.body)
                    .font(.subheadline)
                Text(comment.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                store.deleteVideo(videoID)
                store.videoToDetail = nil
                dismiss()
            } label: {
                Label("Delete Video", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}
