import SwiftUI
import AppKit
import WebKit
import AVKit
import UniformTypeIdentifiers

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
    @State private var kindFilter: HostedMediaKind?
    @State private var tagFilter: String?

    private var filtered: [HostedVideo] {
        var list = store.sortedHostedVideos
        if let kindFilter {
            list = list.filter { $0.kind == kindFilter }
        }
        if let tagFilter {
            list = list.filter { $0.tagList.contains(where: { $0.caseInsensitiveCompare(tagFilter) == .orderedSame }) }
        }
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
            filterBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if filtered.isEmpty {
                        Text("No hosted media yet. Add a local audio, video, image, or a YouTube link — they all live here with comments.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(filtered) { video in
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
            HostedVideoEditSheet()
                .environmentObject(store)
        }
        .sheet(item: $editing) { video in
            HostedVideoDetailSheet(video: video)
                .environmentObject(store)
        }
        .confirmationDialog("Delete this media and its comments?", isPresented: Binding(
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
                Text("Media Host")
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
                Label("Add Media", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip("All", isOn: kindFilter == nil) { kindFilter = nil }
            ForEach(HostedMediaKind.allCases) { kind in
                filterChip(kind.label, isOn: kindFilter == kind) {
                    kindFilter = kind
                }
            }
            Spacer()
            if store.hostedVideoTagList.count > 0 {
                Divider().frame(height: 16)
                Menu {
                    Button("All tags") { tagFilter = nil }
                    Divider()
                    ForEach(store.hostedVideoTagList, id: \.self) { tag in
                        Button(tag) { tagFilter = tag }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                        Text(tagFilter ?? "Tag")
                    }
                    .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func filterChip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(isOn ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isOn ? Color.accentColor : Color.gray.opacity(0.12), in: Capsule())
                .foregroundStyle(isOn ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search media…", text: $searchText)
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
            MediaThumbView(video: video, width: 120, height: 72)
                .frame(width: 120, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(video.title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    Spacer()
                    Label(video.kind.label, systemImage: video.kind.symbol)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(video.kind.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(video.kind.color.opacity(0.15), in: Capsule())
                }
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
                if !video.tagList.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(video.tagList, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(.blue.opacity(0.1), in: Capsule())
                        }
                    }
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
                            .foregroundStyle(video.kind.color)
                    }
                    .buttonStyle(.borderless)
                    .help("Open — watch, listen, comment")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete media")
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

// MARK: - Media thumbnail by kind

struct MediaThumbView: View {
    let video: HostedVideo
    var width: CGFloat = 120
    var height: CGFloat = 72

    var body: some View {
        Group {
            if let id = youtubeVideoID(from: video.url) {
                YouTubeThumb(videoID: id)
            } else if video.kind == .image {
                if let fileURL = localFileURL, let image = NSImage(contentsOf: fileURL) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholder
                }
            } else {
                placeholder
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }

    private var localFileURL: URL? {
        guard !video.filename.isEmpty else { return nil }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("CommentTracker/HostedMedia").appendingPathComponent(video.filename)
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(video.kind.color.opacity(0.12))
            .frame(width: width, height: height)
            .overlay(
                Image(systemName: video.kind.symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(video.kind.color)
            )
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
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var existing: HostedVideo? = nil

    @State private var title = ""
    @State private var description = ""
    @State private var url = ""
    @State private var kind: HostedMediaKind = .youtube
    @State private var tags = ""
    @State private var selectedFileURL: URL?
    @State private var importingFile = false

    private var youtubeID: String? { youtubeVideoID(from: url) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Media" : "Edit Media")
                .font(.title2.bold())

            TextField("Name / Title", text: $title)
                .textFieldStyle(.roundedBorder)

            Picker("Type", selection: $kind) {
                ForEach(HostedMediaKind.allCases) { k in
                    Label(k.label, systemImage: k.symbol).tag(k)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            switch kind {
            case .youtube, .link:
                TextField("Link (\(kind == .youtube ? "YouTube…" : "https://…"))", text: $url)
                    .textFieldStyle(.roundedBorder)
                if let id = youtubeID {
                    YouTubeEmbedView(videoID: id)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            case .audio, .video, .image:
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(selectedFileURL?.lastPathComponent ?? "No local file selected")
                            .font(.caption)
                            .foregroundStyle(selectedFileURL == nil ? .tertiary : .primary)
                            .lineLimit(1)
                        Spacer()
                        Button(selectedFileURL == nil ? "Choose File…" : "Replace…") {
                            importingFile = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(8)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    Text("The file is copied into the app's storage.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text("Tags — comma separated")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("e.g. music, lecture, clip", text: $tags)
                .textFieldStyle(.roundedBorder)

            Text("Description — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $description)
                .font(.body.monospaced())
                .frame(height: 80)
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
                    save()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 520)
        .fileImporter(isPresented: $importingFile, allowedContentTypes: allowedTypes) { result in
            if case .success(let url) = result {
                selectedFileURL = url
                if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    title = url.deletingPathExtension().lastPathComponent
                }
            }
        }
        .onAppear {
            if let existing {
                title = existing.title
                description = existing.description
                url = existing.url
                kind = existing.kind
                tags = existing.tags
            }
        }
    }

    private var allowedTypes: [UTType] {
        switch kind {
        case .audio: return [.audio]
        case .video: return [.movie, .video]
        case .image: return [.image]
        default: return [.item]
        }
    }

    private func save() {
        if let existing {
            if let fileURL = selectedFileURL {
                let replaced = store.addHostedLocalFileReplacing(existing: existing, from: fileURL, tags: tags, title: title, description: description)
                if !replaced {
                    store.updateHostedMedia(id: existing.id, title: title, description: description, url: url, kind: kind, tags: tags)
                }
            } else {
                store.updateHostedMedia(id: existing.id, title: title, description: description, url: url, kind: kind, tags: tags)
            }
        } else {
            if let fileURL = selectedFileURL {
                store.addHostedLocalFile(title: title, description: description, tags: tags, from: fileURL)
            } else {
                store.addHostedMedia(title: title, description: description, kind: kind, url: url, tags: tags)
            }
        }
        dismiss()
    }
}

// MARK: - Detail sheet (play + comments + nested replies)

struct HostedVideoDetailSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let video: HostedVideo

    @State private var editing = false
    @State private var newComment = ""
    @State private var player: AVPlayer?
    @State private var isPlaying = false

    private var comments: [HostedVideoComment] {
        store.topLevelHostedComments(for: video.id)
    }

    private var renderedDescription: AttributedString? {
        let trimmed = video.description.trimmingCharacters(in: .whitespacesAndNewlines)
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
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }
            mediaArea
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
            HostedVideoEditSheet(existing: video)
                .environmentObject(store)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }

    @ViewBuilder
    private var mediaArea: some View {
        switch video.kind {
        case .youtube:
            if let id = youtubeVideoID(from: video.url) {
                YouTubeEmbedView(videoID: id)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                openLinkArea
            }
        case .link:
            openLinkArea
        case .image:
            if let url = localFileURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                emptyMediaArea
            }
        case .audio, .video:
            if let url = localFileURL {
                VStack(spacing: 8) {
                    if video.kind == .video {
                        VideoPlayer(player: player)
                            .frame(height: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Rectangle()
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .frame(height: 90)
                            .overlay(
                                Image(systemName: "waveform")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.purple)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    HStack(spacing: 16) {
                        Button {
                            togglePlayback()
                        } label: {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 30))
                        }
                        .buttonStyle(.borderless)
                        Button {
                            player?.pause()
                            isPlaying = false
                            player?.seek(to: .zero)
                        } label: {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(.borderless)
                        Text("\(video.kind.label) playback")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onAppear {
                    setupPlayer(url: url)
                }
            } else {
                emptyMediaArea
            }
        }
    }

    private var openLinkArea: some View {
        HStack {
            Text("Link media")
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
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyMediaArea: some View {
        HStack {
            Spacer()
            Image(systemName: video.kind.symbol)
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private var localFileURL: URL? {
        guard !video.filename.isEmpty else { return nil }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("CommentTracker/HostedMedia").appendingPathComponent(video.filename)
    }

    private func setupPlayer(url: URL) {
        if player == nil {
            player = AVPlayer(url: url)
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
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
