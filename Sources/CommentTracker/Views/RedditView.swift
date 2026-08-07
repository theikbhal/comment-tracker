import SwiftUI
import AppKit

struct RedditView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: RedditPost?
    @State private var confirmingDelete: RedditPost?

    private var posts: [RedditPost] {
        var list = store.redditPosts
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.redditPost($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    if posts.isEmpty {
                        Text("No posts yet. Start a thread in your own corner of the internet.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(posts) { post in
                        RedditPostCard(post: post) {
                            editing = post
                        } onDelete: {
                            confirmingDelete = post
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            RedditPostSheet { title, body, sub in
                store.addRedditPost(title: title, body: body, sub: sub)
            }
        }
        .sheet(item: $editing) { post in
            RedditDetailSheet(
                post: post,
                onSave: { title, body, sub in
                    store.updateRedditPost(id: post.id, title: title, body: body, sub: sub)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Delete this post and its comments?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let post = confirmingDelete {
                    store.deleteRedditPost(post.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reddit")
                    .font(.title.bold())
                Text("\(store.redditPosts.count) posts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("New Post", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search posts…", text: $searchText)
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

// MARK: - Post card

struct RedditPostCard: View {
    @EnvironmentObject var store: Store
    let post: RedditPost
    let onOpen: () -> Void
    let onDelete: () -> Void

    private var commentCount: Int {
        store.redditComments(for: post.id).count
    }

    private var renderedBody: AttributedString? {
        let trimmed = post.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            voteColumn
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(post.subText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text(post.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(post.votes)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(post.votes > 0 ? .orange : .secondary)
                        .monospacedDigit()
                }
                Text(post.title)
                    .font(.subheadline.weight(.bold))
                if let rendered = renderedBody {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
                HStack(spacing: 10) {
                    Label("\(commentCount)", systemImage: "bubble.left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        onOpen()
                    } label: {
                        Label("Open", systemImage: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Delete post")
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
        .onTapGesture { onOpen() }
        .contextMenu {
            Button { onOpen() } label: {
                Label("Open thread…", systemImage: "arrow.up.left.and.arrow.down.right")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var voteColumn: some View {
        VStack(spacing: 2) {
            Button {
                store.voteRedditPost(id: post.id, delta: 1)
            } label: {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Upvote")
            Text("\(post.votes)")
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(post.votes > 0 ? .orange : .secondary)
            Button {
                store.voteRedditPost(id: post.id, delta: -1)
            } label: {
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Downvote")
        }
        .padding(.top, 2)
    }
}

// MARK: - Post sheet

struct RedditPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: RedditPost? = nil
    let onSave: (String, String, String) -> Void

    @State private var title = ""
    @State private var sub = ""
    @State private var bodyText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "New Post" : "Edit Post")
                .font(.title2.bold())
            HStack(spacing: 8) {
                TextField("Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                TextField("Sub (r/…)", text: $sub)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 130)
            }
            Text("Body — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $bodyText)
                .font(.body.monospaced())
                .frame(height: 140)
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
                    onSave(title, bodyText, sub)
                    dismiss()
                } label: {
                    Label("Post", systemImage: "paperplane.fill")
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
                sub = existing.sub
                bodyText = existing.body
            }
        }
    }
}

// MARK: - Detail sheet (thread)

struct RedditDetailSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let post: RedditPost
    let onSave: (String, String, String) -> Void

    @State private var editing = false
    @State private var title = ""
    @State private var sub = ""
    @State private var bodyText = ""
    @State private var newComment = ""

    private var comments: [RedditComment] {
        store.topLevelRedditComments(for: post.id)
    }

    private var renderedBody: AttributedString? {
        let trimmed = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(post.subText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.blue)
                Text("· \(post.votes) votes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    editing = true
                    title = post.title
                    sub = post.sub
                    bodyText = post.body
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
            }
            Text(post.title)
                .font(.title3.bold())
            if let rendered = renderedBody {
                Text(rendered)
                    .font(.callout)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.openURL, OpenURLAction { url in
                        NSWorkspace.shared.open(url)
                        return .handled
                    })
            }
            commentsSection
        }
        .padding(20)
        .frame(width: 560, height: 680)
        .sheet(isPresented: $editing) {
            RedditPostSheet(existing: post) { t, b, s in
                onSave(t, b, s)
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
                        store.addRedditComment(postID: post.id, parentID: nil, body: newComment)
                        newComment = ""
                    }
                Button {
                    store.addRedditComment(postID: post.id, parentID: nil, body: newComment)
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
                        Text("No comments yet")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 10)
                    }
                    ForEach(comments) { comment in
                        RedditCommentThread(comment: comment, postID: post.id)
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

struct RedditCommentThread: View {
    @EnvironmentObject var store: Store
    let comment: RedditComment
    let postID: Int

    @State private var showingReply = false
    @State private var replyText = ""

    private var replies: [RedditComment] {
        store.redditReplies(to: comment.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            commentRow(comment, indent: 0)
            ForEach(replies) { reply in
                commentRow(reply, indent: 1)
            }
        }
    }

    private func commentRow(_ c: RedditComment, indent: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(c.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        Spacer()
                        Button {
                            store.deleteRedditComment(c.id)
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
                            store.addRedditComment(postID: postID, parentID: comment.id, body: replyText)
                            replyText = ""
                            showingReply = false
                        }
                    Button {
                        store.addRedditComment(postID: postID, parentID: comment.id, body: replyText)
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
