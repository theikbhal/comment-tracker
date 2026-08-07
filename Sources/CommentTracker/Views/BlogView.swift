import SwiftUI
import AppKit

private let blogPageSize = 15

struct BlogView: View {
    @EnvironmentObject var store: Store
    @State private var searchText = ""
    @State private var filter: BlogPostStatus?
    @State private var editingPost: BlogPost?
    @State private var viewingPost: BlogPost?
    @State private var showingNewPost = false
    @State private var loaded = blogPageSize

    private var allPosts: [BlogPost] {
        var list = store.blogPosts
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { store.blogPost($0, matches: searchText) }
        }
        if let filter {
            list = list.filter { $0.status == filter }
        }
        return list
    }

    private var shownPosts: [BlogPost] { Array(allPosts.prefix(loaded)) }
    private var canLoadMore: Bool { loaded < allPosts.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(shownPosts) { post in
                        BlogPostCardView(
                            post: post,
                            onOpen: { viewingPost = post },
                            onEdit: { editingPost = post },
                            onDelete: { store.deleteBlogPost(post.id) }
                        )
                    }
                    if allPosts.isEmpty {
                        emptyState
                    } else if canLoadMore {
                        Button {
                            loaded += blogPageSize
                        } label: {
                            Text("Show older posts (\(allPosts.count - loaded) remaining)")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .padding(.horizontal, 16)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20)
                .frame(maxWidth: 680, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingNewPost) {
            BlogPostEditSheet()
                .environmentObject(store)
        }
        .sheet(item: $editingPost) { post in
            BlogPostEditSheet(post: post)
                .environmentObject(store)
        }
        .sheet(item: $viewingPost) { post in
            BlogPostViewSheet(post: post)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Blog")
                    .font(.title.bold())
                Text("\(store.blogPosts.count) posts · \(store.blogPosts.filter { $0.status == .published }.count) published")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Menu {
                Button {
                    filter = nil
                    loaded = blogPageSize
                } label: {
                    Label("All posts", systemImage: filter == nil ? "checkmark" : "")
                }
                Button {
                    filter = .draft
                    loaded = blogPageSize
                } label: {
                    Label("Drafts", systemImage: filter == .draft ? "checkmark" : "")
                }
                Button {
                    filter = .published
                    loaded = blogPageSize
                } label: {
                    Label("Published", systemImage: filter == .published ? "checkmark" : "")
                }
            } label: {
                Label(filter?.displayName ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            Button {
                showingNewPost = true
            } label: {
                Label("New post", systemImage: "square.and.pencil")
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
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
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
        .frame(width: 220)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "newspaper")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(filter == nil ? "No posts yet — write your first one" : filter == .draft ? "No drafts" : "No published posts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct BlogPostCardView: View {
    @EnvironmentObject var store: Store
    let post: BlogPost
    var onOpen: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: post.status == .published ? "newspaper.fill" : "doc.text")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(post.status.color.gradient, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(post.status.displayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(post.status.color)
                        Text(post.status == .published && post.publishedAt != nil
                             ? post.publishedAt!.formatted(date: .abbreviated, time: .omitted)
                             : "Edited \(post.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(post.title)
                        .font(.headline)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !post.body.isEmpty {
                        Text(post.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                    if !post.tagList.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(post.tagList, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                }
            }
            HStack(spacing: 14) {
                Text("\(post.body.count) chars")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
                Spacer()
                Button {
                    onOpen?()
                } label: {
                    Label("View", systemImage: "eye")
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .help("Read the full post")
                Button {
                    onEdit?()
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .help("Edit this post")
                Button {
                    store.setBlogPostStatus(post.id, post.status == .published ? .draft : .published)
                } label: {
                    Label(post.status == .published ? "Unpublish" : "Publish", systemImage: post.status == .published ? "arrow.uturn.backward" : "paperplane")
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .help(post.status == .published ? "Unpublish" : "Publish")
                Button(role: .destructive) {
                    onDelete?()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .help("Delete this post")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.16), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .onTapGesture { onOpen?() }
        .contextMenu {
            Button { onOpen?() } label: { Label("View", systemImage: "eye") }
            Button { onEdit?() } label: { Label("Edit", systemImage: "pencil") }
            Button {
                store.setBlogPostStatus(post.id, post.status == .published ? .draft : .published)
            } label: {
                Label(post.status == .published ? "Unpublish" : "Publish", systemImage: post.status == .published ? "arrow.uturn.backward" : "paperplane")
            }
            Divider()
            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct BlogPostViewSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let post: BlogPost
    @State private var showingEdit = false

    private var fresh: BlogPost? {
        store.blogPosts.first { $0.id == post.id }
    }

    var body: some View {
        let current = fresh ?? post
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Text(current.status.displayName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(current.status.color, in: Capsule())
                        Spacer()
                        Text(current.status == .published && current.publishedAt != nil
                             ? "Published \(current.publishedAt!.formatted(date: .long, time: .shortened))"
                             : "Created \(current.createdAt.formatted(date: .long, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(current.title)
                        .font(.title2.bold())
                    if !current.tagList.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(current.tagList, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1), in: Capsule())
                            }
                        }
                    }
                    Divider()
                    if current.body.isEmpty {
                        Text("No body yet.")
                            .font(.body)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 30)
                    } else {
                        Text(current.body)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text("Last edited \(current.updatedAt.formatted(date: .long, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(20)
            }
            Divider()
            HStack(spacing: 12) {
                Button {
                    store.setBlogPostStatus(current.id, current.status == .published ? .draft : .published)
                } label: {
                    Label(current.status == .published ? "Unpublish" : "Publish", systemImage: current.status == .published ? "arrow.uturn.backward" : "paperplane")
                }
                .buttonStyle(.bordered)
                Button(role: .destructive) {
                    store.deleteBlogPost(current.id)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Edit") {
                    showingEdit = true
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(14)
        }
        .frame(width: 580, height: 520)
        .sheet(isPresented: $showingEdit) {
            if let freshPost = store.blogPosts.first(where: { $0.id == current.id }) {
                BlogPostEditSheet(post: freshPost)
                    .environmentObject(store)
            }
        }
    }
}

struct BlogPostEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let post: BlogPost?

    @State private var title: String
    @State private var bodyText: String
    @State private var tags: String
    @State private var status: BlogPostStatus

    init() {
        self.post = nil
        _title = State(initialValue: "")
        _bodyText = State(initialValue: "")
        _tags = State(initialValue: "")
        _status = State(initialValue: .draft)
    }

    init(post: BlogPost) {
        self.post = post
        _title = State(initialValue: post.title)
        _bodyText = State(initialValue: post.body)
        _tags = State(initialValue: post.tags)
        _status = State(initialValue: post.status)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(post == nil ? "New post" : "Edit post")
                .font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $bodyText)
                .font(.body)
                .frame(minHeight: 200)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            TextField("Tags (comma separated)", text: $tags)
                .textFieldStyle(.roundedBorder)
            HStack {
                Picker("Status", selection: $status) {
                    Text("Draft").tag(BlogPostStatus.draft)
                    Text("Published").tag(BlogPostStatus.published)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(post == nil ? "Create" : "Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 520, height: 420)
    }

    private func save() {
        if let post {
            store.updateBlogPost(id: post.id, title: title, body: bodyText, tags: tags, status: status)
        } else {
            store.addBlogPost(title: title, body: bodyText, tags: tags, status: status)
        }
        dismiss()
    }
}
