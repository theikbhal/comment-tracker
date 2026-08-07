import SwiftUI
import AppKit

let knownAppNames = ["Comment Tracker", "ikbhal-blog", "Ikbhal"]

struct FeatureRequestsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: FeatureRequest?

    private var ideaCount: Int { store.featureRequests(for: .idea).count }
    private var totalCount: Int { store.featureRequests.count }

    private func cards(for status: FeatureRequestStatus) -> [FeatureRequest] {
        store.featureRequests(for: status).filter { store.featureRequest($0, matches: searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(FeatureRequestStatus.allCases) { status in
                        column(status)
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAdd) {
            FeatureRequestAddSheet { app, title, body, link in
                store.addFeatureRequest(app: app, title: title, body: body, link: link)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { request in
            FeatureRequestDetailSheet(
                existing: request,
                onSave: { app, title, body, link in
                    store.updateFeatureRequest(id: request.id, app: app, title: title, body: body, link: link)
                }
            )
            .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Feature Requests")
                    .font(.title.bold())
                Text("\(ideaCount) open ideas · \(totalCount) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Request", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search requests…", text: $searchText)
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

    private func column(_ status: FeatureRequestStatus) -> some View {
        let items = cards(for: status)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: status.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(status.color)
                Text(status.displayName)
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items) { request in
                        FeatureRequestCard(request: request) {
                            editing = request
                        }
                    }
                    if items.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: status.symbol)
                                .font(.system(size: 22))
                                .foregroundStyle(.tertiary)
                            Text("No requests here")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 280)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(status.color.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
    }
}

// MARK: - Card

struct FeatureRequestCard: View {
    @EnvironmentObject var store: Store
    let request: FeatureRequest
    let onOpenFull: () -> Void

    private var commentCount: Int {
        store.featureRequestComments(for: request.id).count
    }

    private var renderedBody: AttributedString? {
        let trimmed = request.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: request.status.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(request.status.color.gradient, in: RoundedRectangle(cornerRadius: 6))
                Text(request.title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
                statusMenu
            }
            if !request.app.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 9))
                    Text(request.app)
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(.indigo)
            }
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
            HStack(spacing: 8) {
                if commentCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 9))
                        Text("\(commentCount)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if !request.link.isEmpty {
                    Button {
                        if let url = URL(string: request.link.hasPrefix("http") ? request.link : "https://\(request.link)") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Open link")
                }
                Text(request.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(request.status.color)
                .frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { onOpenFull() }
        .contextMenu {
            Button { onOpenFull() } label: {
                Label("Edit request…", systemImage: "pencil")
            }
            if !request.link.isEmpty {
                Button {
                    if let url = URL(string: request.link.hasPrefix("http") ? request.link : "https://\(request.link)") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Open link", systemImage: "arrow.up.right.square")
                }
            }
            Divider()
            Button(role: .destructive) {
                store.deleteFeatureRequest(request.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(FeatureRequestStatus.allCases) { s in
                Button {
                    store.setFeatureRequestStatus(id: request.id, status: s)
                } label: {
                    if s == request.status {
                        Label(s.displayName, systemImage: "checkmark")
                    } else {
                        Text(s.displayName)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 13))
                .foregroundStyle(request.status.color)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Move to another status")
    }
}

// MARK: - Add sheet

struct FeatureRequestAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String, String, String) -> Void

    @State private var app = ""
    @State private var title = ""
    @State private var note = ""
    @State private var link = ""

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Feature Request")
                .font(.title2.bold())

            HStack(spacing: 8) {
                TextField("App (optional)", text: $app)
                    .textFieldStyle(.roundedBorder)
                Menu {
                    ForEach(knownAppNames, id: \.self) { name in
                        Button(name) { app = name }
                    }
                } label: {
                    Image(systemName: "chevron.down.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Pick an app")
            }

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Link (optional)", text: $link)
                .textFieldStyle(.roundedBorder)
            Text("Note — markdown supported ([link](https://…), **bold**, lists)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 120)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            if let rendered = renderedNote, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(rendered)
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(app, title, note, link)
                    dismiss()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}

// MARK: - Detail sheet

struct FeatureRequestDetailSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let existing: FeatureRequest
    let onSave: (String, String, String, String) -> Void

    @State private var app = ""
    @State private var title = ""
    @State private var note = ""
    @State private var link = ""
    @State private var newComment = ""

    private var comments: [FeatureRequestComment] {
        store.featureRequestComments(for: existing.id)
    }

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Edit Feature Request")
                    .font(.title2.bold())
                Spacer()
                statusMenu
            }

            HStack(spacing: 8) {
                TextField("App (optional)", text: $app)
                    .textFieldStyle(.roundedBorder)
                Menu {
                    ForEach(knownAppNames, id: \.self) { name in
                        Button(name) { app = name }
                    }
                } label: {
                    Image(systemName: "chevron.down.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Pick an app")
            }

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Link (optional)", text: $link)
                .textFieldStyle(.roundedBorder)
            Text("Note — markdown supported ([link](https://…), **bold**, lists)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 100)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Comments")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(comments.count)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
                ScrollView {
                    VStack(spacing: 6) {
                        if comments.isEmpty {
                            Text("No comments yet")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.vertical, 8)
                        }
                        ForEach(comments) { comment in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "bubble.left.fill")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Text(comment.body)
                                    .font(.callout)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(comment.createdAt.formatted(date: .numeric, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Button {
                                    store.deleteFeatureRequestComment(comment.id)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.tertiary)
                                }
                                .buttonStyle(.plain)
                                .help("Delete comment")
                            }
                            .padding(8)
                            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .frame(maxHeight: 130)
                HStack(spacing: 8) {
                    TextField("Add a comment…", text: $newComment)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            store.addFeatureRequestComment(requestID: existing.id, body: newComment)
                            newComment = ""
                        }
                    Button {
                        store.addFeatureRequestComment(requestID: existing.id, body: newComment)
                        newComment = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                    }
                    .buttonStyle(.borderless)
                    .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(app, title, note, link)
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
        .frame(width: 500, height: 640)
        .onAppear {
            app = existing.app
            title = existing.title
            note = existing.body
            link = existing.link
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(FeatureRequestStatus.allCases) { s in
                Button {
                    store.setFeatureRequestStatus(id: existing.id, status: s)
                } label: {
                    if s == existing.status {
                        Label(s.displayName, systemImage: "checkmark")
                    } else {
                        Text(s.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: existing.status.symbol)
                    .font(.system(size: 12, weight: .semibold))
                Text(existing.status.displayName)
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(existing.status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(existing.status.color.opacity(0.14), in: Capsule())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
