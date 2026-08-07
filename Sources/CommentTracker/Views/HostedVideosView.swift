import SwiftUI
import AppKit
import WebKit

func youtubeVideoID(from urlString: String) -> String? {
    guard let url = URL(string: urlString) else { return nil }
    if url.host?.contains("youtu.be") == true {
        return url.pathComponents.filter { $0 != "/" }.first
    }
    if url.host?.contains("youtube.com") == true {
        if let comp = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let item = comp.queryItems?.first(where: { $0.name == "v" }), let id = item.value {
            return id
        }
        if url.pathComponents.count > 2, ["embed", "shorts"].contains(url.pathComponents[1]) {
            return url.pathComponents[2]
        }
    }
    return nil
}

// MARK: - YouTube embed

struct YouTubeEmbedView: NSViewRepresentable {
    let videoID: String

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: "https://www.youtube.com/embed/\(videoID)?playsinline=1") else { return }
        webView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, WKNavigationDelegate {}
}

// MARK: - Main view

struct HostedVideosView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: HostedVideo?
    @State private var confirmingDelete: HostedVideo?

    private var videos: [HostedVideo] {
        var list = store.sortedHostedVideos
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.hostedVideo($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if videos.isEmpty {
                        Text("No hosted videos yet. Add one — paste a YouTube link and it plays right here with comments.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(videos) { video in
                        HostedVideoCard(video: video) {
                            editing = video
                        } onDelete: {
                            confirmingDelete = video
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 760, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            HostedVideoEditSheet { title, description, url in
                store.addHostedVideo(title: title, description: description, url: url)
            }
        }
        .sheet(item: $editing) { video in
            HostedVideoDetailSheet(
                video: video,
                onSave: { title, description, url in
                    store.updateHostedVideo(id: video.id, title: title, description: description, url: url)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this video and its comments?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let video = confirmingDelete {
                    store.deleteHostedVideo(video.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Mini Videos")
                    .font(.title.bold())
                Text("\(store.hostedVideos.count) hosted")
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
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search videos…", text: $searchText)
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

// MARK: - Card

struct HostedVideoCard: View {
    @EnvironmentObject var store: Store
    let video: HostedVideo
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var commentCount: Int {
        store.hostedVideoComments(for: video.id).count
    }

    private var renderedDescription: AttributedString? {
        let trimmed = video.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let id = youtubeVideoID(from: video.url) {
                YouTubeThumb(videoID: id)
                    .frame(width: 120, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 120, height: 68)
                    .overlay(Image(systemName: "play.rectangle.fill").foregroundStyle(.tertiary))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline.weight(.bold))
                if let rendered = renderedDescription {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
                HStack(spacing: 10) {
                    Text("\(commentCount) comment\(commentCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(video.updatedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Open — watch, edit, comment")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete video")
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
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { onEdit() }
        .contextMenu {
            Button { onEdit() } label: {
                Label("Open…", systemImage: "play.circle.fill")
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

// MARK: - YouTube thumbnail

struct YouTubeThumb: NSViewRepresentable {
    let videoID: String

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.15).cgColor
        imageView.image = NSImage(systemSymbolName: "play.fill", accessibilityDescription: nil)
        imageView.contentTintColor = .white
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        if let url = URL(string: "https://img.youtube.com/vi/\(videoID)/mqdefault.jpg") {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data, let image = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    nsView.image = image
                    nsView.contentTintColor = nil
                }
            }.resume()
        }
    }
}

// MARK: - Add / edit sheet

struct HostedVideoEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: HostedVideo? = nil
    let onSave: (String, String, String) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var url = ""

    private var youtubeID: String? { youtubeVideoID(from: url) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Video" : "Edit Video")
                .font(.title2.bold())
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Video link (YouTube…)", text: $url)
                .textFieldStyle(.roundedBorder)
            if let id = youtubeID {
                YouTubeEmbedView(videoID: id)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Text("Description — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $description)
                .font(.body.monospaced())
                .frame(height: 90)
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
                    onSave(title, description, url)
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
        .frame(width: 480)
        .onAppear {
            if let existing {
                title = existing.title
                description = existing.description
                url = existing.url
            }
        }
    }
}

// MARK: - Detail sheet (watch + comments + nested replies)

struct HostedVideoDetailSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let video: HostedVideo
    let onSave: (String, String, String) -> Void

    @State private var editing = false
    @State private var title = ""
    @State private var description = ""
    @State private var url = ""
    @State private var newComment = ""

    private var comments: [HostedVideoComment] {
        store.topLevelHostedComments(for: video.id)
    }

    private var renderedDescription: AttributedString? {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(video.title)
                    .font(.title2.bold())
                Spacer()
                Button {
                    editing = true
                    title = video.title
                    description = video.description
                    url = video.url
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }
            if let id = youtubeVideoID(from: video.url) {
                YouTubeEmbedView(videoID: id)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if !video.url.isEmpty {
                HStack {
                    Text("Not a YouTube link.")
                        .font(.caption)
                    Button {
                        if let u = URL(string: video.url.hasPrefix("http") ? video.url : "https://\(video.url)") {
                            NSWorkspace.shared.open(u)
                        }
                    } label: {
                        Label("Open in browser", systemImage: "arrow.up.right.square")
                    }
                    .buttonStyle(.link)
                }
                .foregroundStyle(.secondary)
            }
            if let rendered = renderedDescription {
                Text(rendered)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .environment(\.openURL, OpenURLAction { url in
                        NSWorkspace.shared.open(url)
                        return .handled
                    })
            }

            commentsSection
        }
        .padding(20)
        .frame(width: 560, height: 700)
        .sheet(isPresented: $editing) {
            HostedVideoEditSheet(existing: video) { t, d, u in
                onSave(t, d, u)
            }
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
                        store.addHostedVideoComment(videoID: video.id, parentID: nil, body: newComment)
                        newComment = ""
                    }
                Button {
                    store.addHostedVideoComment(videoID: video.id, parentID: nil, body: newComment)
                    newComment = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                }
                .buttonStyle(.borderless)
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ScrollView {
                VStack(spacing: 10) {
                    if comments.isEmpty {
                        Text("Be the first to comment")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 10)
                    }
                    ForEach(comments) { comment in
                        CommentThread(comment: comment, videoID: video.id)
                            .environmentObject(store)
                    }
                }
            }
        }
        .padding(12)
        .background(.background.secondary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Comment thread with nested replies

struct CommentThread: View {
    @EnvironmentObject var store: Store
    let comment: HostedVideoComment
    let videoID: Int

    @State private var showingReply = false
    @State private var replyText = ""

    private var replies: [HostedVideoComment] {
        store.hostedReplies(to: comment.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            commentRow(comment, indent: 0)
            ForEach(replies) { reply in
                commentRow(reply, indent: 1)
            }
        }
    }

    private func commentRow(_ c: HostedVideoComment, indent: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(c.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        if c.isReply {
                            Text("reply")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                        Spacer()
                        Button {
                            store.deleteHostedVideoComment(c.id)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help("Delete comment")
                    }
                    Text(c.body)
                        .font(.callout)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !c.isReply {
                        Button {
                            showingReply.toggle()
                        } label: {
                            Text("Reply")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.leading, indent == 0 ? 0 : 24)
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(indent == 0 ? 0 : 0.5), in: RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .leading) {
                if indent > 0 {
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 2)
                        .offset(x: -8)
                }
            }

            if !c.isReply, showingReply {
                HStack(spacing: 8) {
                    TextField("Reply…", text: $replyText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            store.addHostedVideoComment(videoID: videoID, parentID: comment.id, body: replyText)
                            replyText = ""
                            showingReply = false
                        }
                    Button {
                        store.addHostedVideoComment(videoID: videoID, parentID: comment.id, body: replyText)
                        replyText = ""
                        showingReply = false
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.borderless)
                    .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.leading, 40)
            }
        }
    }
}
