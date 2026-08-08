import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BloggingSitesView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: BlogSite?
    @State private var confirmingDelete: BlogSite?
    @State private var expandedID: Int?
    @State private var languageFilter: String?
    @State private var tierFilter: String?

    private var filtered: [BlogSite] {
        var list = store.blogSites
        if let languageFilter {
            list = list.filter { $0.language.caseInsensitiveCompare(languageFilter) == .orderedSame }
        }
        if let tierFilter {
            list = list.filter { $0.tier == tierFilter }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.blogSite($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            milestoneBar
            Divider()
            filterBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if filtered.isEmpty {
                        Text("No blogging websites yet. Add your first one — pick a theme, language, target country, and start building toward 313.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(filtered) { site in
                        BlogSiteCard(
                            site: site,
                            isExpanded: expandedID == site.id,
                            onToggleExpand: { expandedID = expandedID == site.id ? nil : site.id },
                            onEdit: { editing = site },
                            onDelete: { confirmingDelete = site },
                            onMoveUp: { store.moveBlogSite(id: site.id, direction: -1) },
                            onMoveDown: { store.moveBlogSite(id: site.id, direction: 1) }
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: 720, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            BlogSiteEditSheet()
                .environmentObject(store)
        }
        .sheet(item: $editing) { site in
            BlogSiteEditSheet(existing: site)
                .environmentObject(store)
        }
        .confirmationDialog("Delete this website and all its posts and assets?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let site = confirmingDelete {
                    store.deleteBlogSite(site.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("313 Blogging Websites")
                    .font(.title.bold())
                Text("\(store.blogSites.count) sites · \(store.adsenseApprovedCount) AdSense · \(store.blogPosts.count) posts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Website", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var milestoneBar: some View {
        let count = store.blogSites.count
        let reached = blogSiteMilestones.filter { $0 <= count }.count
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Milestones")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(count) / 313")
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(count >= 313 ? .green : .primary)
            }
            ProgressView(value: Double(count), total: 313)
                .progressViewStyle(.linear)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(blogSiteMilestones, id: \.self) { m in
                        let done = count >= m
                        Text("\(m)")
                            .font(.system(size: 10, weight: done ? .bold : .regular))
                            .foregroundStyle(done ? .white : .secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(done ? Color.green : Color.gray.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .padding(16)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip("All", isOn: languageFilter == nil && tierFilter == nil) {
                languageFilter = nil
                tierFilter = nil
            }
            Divider().frame(height: 16)
            Menu {
                Button("All languages") { languageFilter = nil }
                Divider()
                ForEach(store.blogLanguages, id: \.self) { lang in
                    Button(lang) { languageFilter = lang }
                }
            } label: {
                filterMenuLabel("Language", selection: languageFilter)
            }
            Menu {
                Button("All tiers") { tierFilter = nil }
                Divider()
                ForEach(blogCountryTiers, id: \.self) { tier in
                    Button(tier) { tierFilter = tier }
                }
            } label: {
                filterMenuLabel("Tier", selection: tierFilter)
            }
            Spacer()
            if store.blogTierCounts.count > 0 {
                HStack(spacing: 6) {
                    ForEach(blogCountryTiers, id: \.self) { tier in
                        if let count = store.blogTierCounts[tier] {
                            Text("\(tier): \(count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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

    private func filterMenuLabel(_ title: String, selection: String?) -> some View {
        HStack(spacing: 4) {
            Text(selection ?? title)
                .font(.caption)
            Image(systemName: "chevron.down")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search sites…", text: $searchText)
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
        .frame(width: 200)
    }
}

// MARK: - Site card

struct BlogSiteCard: View {
    @EnvironmentObject var store: Store
    let site: BlogSite
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private var editors: [BlogSiteEditor] {
        store.blogEditors(for: site.id)
    }

    private var posts: [BlogSitePost] {
        store.blogPosts(for: site.id)
    }

    private var publishedPosts: Int {
        posts.filter { $0.status == "published" }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(site.name)
                            .font(.headline)
                        if site.adsense {
                            Label("AdSense", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.15), in: Capsule())
                        }
                    }
                    if !site.domain.isEmpty {
                        Text(site.domain)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    if !site.theme.isEmpty {
                        Text(site.theme)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack(spacing: 6) {
                        chip(site.language, icon: "globe")
                        chip(site.country, icon: "mappin.and.ellipse")
                        chip(site.tier, icon: "chart.bar.fill")
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(posts.count) posts · \(publishedPosts) pub")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Text("\(editors.count) editor\(editors.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    HStack(spacing: 4) {
                        Button(action: onMoveUp) {
                            Image(systemName: "arrow.up").font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .disabled(site.position == store.blogSites.map(\.position).min())
                        .help("Move up")
                        Button(action: onMoveDown) {
                            Image(systemName: "arrow.down").font(.system(size: 10))
                        }
                        .buttonStyle(.borderless)
                        .help("Move down")
                        Button(action: onEdit) {
                            Image(systemName: "pencil").font(.system(size: 11))
                        }
                        .buttonStyle(.borderless)
                        .help("Edit website")
                        Button(action: onDelete) {
                            Image(systemName: "trash").font(.system(size: 11))
                        }
                        .buttonStyle(.borderless)
                        .help("Delete website")
                    }
                    .foregroundStyle(.secondary)
                }
            }

            if isExpanded {
                Divider()
                expandedContent
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
        .onTapGesture { onToggleExpand() }
        .contextMenu {
            Button { onToggleExpand() } label: {
                Label(isExpanded ? "Collapse" : "Expand", systemImage: isExpanded ? "chevron.up" : "chevron.down")
            }
            Button { onEdit() } label: {
                Label("Edit…", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func chip(_ text: String, icon: String) -> some View {
        Group {
            if !text.isEmpty {
                Label(text, systemImage: icon)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            editorsSection
            postsSection
        }
    }

    private var editorsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Editors & Team")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if editors.isEmpty {
                Text("No editors yet.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            ForEach(editors) { editor in
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(editor.name)
                        .font(.caption)
                    if !editor.role.isEmpty {
                        Text("· \(editor.role)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Button {
                        store.deleteBlogEditor(editor.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            BlogEditorAddField(siteID: site.id)
        }
    }

    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Posts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if posts.isEmpty {
                Text("No posts yet.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            ForEach(posts) { post in
                BlogPostRow(post: post, site: site)
                    .environmentObject(store)
            }
            BlogPostAddField(siteID: site.id)
        }
    }
}

// MARK: - Editor add field

struct BlogEditorAddField: View {
    @EnvironmentObject var store: Store
    let siteID: Int
    @State private var name = ""
    @State private var role = ""

    var body: some View {
        HStack(spacing: 6) {
            TextField("Editor name", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 180)
            TextField("Role", text: $role)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
            Button {
                store.addBlogEditor(siteID: siteID, name: name, role: role)
                name = ""
                role = ""
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

// MARK: - Post add field

struct BlogPostAddField: View {
    @EnvironmentObject var store: Store
    let siteID: Int
    @State private var title = ""

    var body: some View {
        HStack(spacing: 6) {
            TextField("New post title…", text: $title)
                .textFieldStyle(.roundedBorder)
            Button {
                store.addBlogSitePost(siteID: siteID, title: title, description: "", url: "")
                title = ""
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}

// MARK: - Post row

struct BlogPostRow: View {
    @EnvironmentObject var store: Store
    let post: BlogSitePost
    let site: BlogSite

    @State private var expanded = false
    @State private var importingAsset = false
    @State private var caption = ""

    private var assets: [BlogPostAsset] {
        store.blogPostAssets(for: post.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: post.status == "published" ? "checkmark.circle.fill" : "circle.dotted")
                    .font(.system(size: 11))
                    .foregroundStyle(post.status == "published" ? .green : .orange)
                Text(post.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                if !post.url.isEmpty {
                    Text("· link")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                Spacer()
                Button {
                    store.updateBlogSitePost(id: post.id, title: post.title, description: post.description, url: post.url, status: post.status == "published" ? "draft" : "published")
                } label: {
                    Text(post.status == "published" ? "Unpublish" : "Publish")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(post.status == "published" ? .orange : .green)
                Button {
                    expanded.toggle()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 6) {
                    if !post.description.isEmpty {
                        Text(post.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    TextField("Post URL (optional)", text: Binding(
                        get: { post.url },
                        set: { store.updateBlogSitePost(id: post.id, title: post.title, description: post.description, url: $0, status: post.status) }
                    ))
                    .textFieldStyle(.roundedBorder)
                    TextField("Description (markdown ok)", text: Binding(
                        get: { post.description },
                        set: { store.updateBlogSitePost(id: post.id, title: post.title, description: $0, url: post.url, status: post.status) }
                    ))
                    .textFieldStyle(.roundedBorder)

                    HStack(spacing: 8) {
                        Text("Assets")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Button {
                            importingAsset = true
                        } label: {
                            Label("Add Image / Video", systemImage: "paperclip")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        Spacer()
                    }
                    .fileImporter(isPresented: $importingAsset, allowedContentTypes: [.image, .movie, .audio]) { result in
                        if case .success(let url) = result {
                            let kind: String
                            switch url.pathExtension.lowercased() {
                            case "mp3", "m4a", "wav", "aac": kind = "audio"
                            case "mp4", "mov", "m4v", "webm": kind = "video"
                            default: kind = "image"
                            }
                            store.addBlogPostAsset(postID: post.id, kind: kind, from: url, caption: "")
                        }
                    }

                    if assets.isEmpty {
                        Text("No assets yet.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    ForEach(assets) { asset in
                        BlogAssetRow(asset: asset)
                            .environmentObject(store)
                    }
                    if !assets.isEmpty {
                        HStack(spacing: 6) {
                            TextField("Caption for next asset", text: $caption)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                store.addBlogPostAssetCaption(caption: caption, for: assets.last)
                                caption = ""
                            } label: {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.borderless)
                            .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(8)
        .background(.background.secondary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Asset row

struct BlogAssetRow: View {
    @EnvironmentObject var store: Store
    let asset: BlogPostAsset

    private var localURL: URL? {
        guard !asset.filename.isEmpty else { return nil }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("CommentTracker/BlogAssets").appendingPathComponent(asset.filename)
    }

    private var symbol: String {
        switch asset.kind {
        case "video": return "film.fill"
        case "audio": return "waveform"
        default: return "photo.fill"
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            if asset.kind == "image", let url = localURL, let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 28)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(asset.filename)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !asset.caption.isEmpty {
                    Text(asset.caption)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button {
                if let url = localURL {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } label: {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.borderless)
            .help("Show in Finder")
            Button {
                store.deleteBlogPostAsset(asset.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Delete asset")
        }
        .padding(6)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Edit sheet

struct BlogSiteEditSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var existing: BlogSite? = nil

    @State private var name = ""
    @State private var domain = ""
    @State private var theme = ""
    @State private var country = ""
    @State private var language = "English"
    @State private var tier = "Tier 3"
    @State private var adsense = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(existing == nil ? "Add Website" : "Edit Website")
                .font(.title2.bold())

            TextField("Site name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Domain (optional)", text: $domain)
                .textFieldStyle(.roundedBorder)
            TextField("Theme / niche", text: $theme)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Language")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $language) {
                        ForEach(blogLanguages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    .labelsHidden()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target country")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. India, Brazil", text: $country)
                        .textFieldStyle(.roundedBorder)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tier")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $tier) {
                        ForEach(blogCountryTiers, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    .labelsHidden()
                }
            }

            Toggle("Google AdSense approved / enabled", isOn: $adsense)
                .toggleStyle(.checkbox)

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    if let existing {
                        store.updateBlogSite(id: existing.id, name: name, domain: domain, theme: theme, country: country, language: language, tier: tier, adsense: adsense)
                    } else {
                        store.addBlogSite(name: name, domain: domain, theme: theme, country: country, language: language, tier: tier, adsense: adsense)
                    }
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 480)
        .onAppear {
            if let existing {
                name = existing.name
                domain = existing.domain
                theme = existing.theme
                country = existing.country
                language = existing.language.isEmpty ? "English" : existing.language
                tier = existing.tier.isEmpty ? "Tier 3" : existing.tier
                adsense = existing.adsense
            }
        }
    }
}
