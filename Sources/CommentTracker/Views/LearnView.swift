import SwiftUI
import AppKit
import WebKit

struct LearnView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var editing: LearnItem?
    @State private var confirmingDelete: LearnItem?
    @State private var searchText = ""
    @State private var categoryFilter: String?

    private var filtered: [LearnItem] {
        var list = store.sortedLearnItems
        if let categoryFilter {
            list = list.filter { ($0.category.isEmpty ? "Uncategorized" : $0.category).caseInsensitiveCompare(categoryFilter) == .orderedSame }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.learnItem($0, matches: q) }
        }
        return list
    }

    private var due: [LearnItem] { filtered.filter { $0.nextRevisionAt != nil && ($0.nextRevisionAt! <= Date() || Calendar.current.isDateInToday($0.nextRevisionAt!)) } }
    private var upcoming: [LearnItem] { filtered.filter { $0.nextRevisionAt != nil && $0.nextRevisionAt! > Date() && !Calendar.current.isDateInToday($0.nextRevisionAt!) } }
    private var fresh: [LearnItem] { filtered.filter { $0.nextRevisionAt == nil } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            filterBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if filtered.isEmpty {
                        Text("Nothing here yet. Add something you're learning — a video, topic, or skill — and the app will tell you when to revise it.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    } else {
                        if !due.isEmpty {
                            revisionSection(title: "Due — revise now", items: due, symbol: "exclamationmark.circle.fill", tint: .orange)
                        }
                        if !upcoming.isEmpty {
                            revisionSection(title: "Upcoming revisions", items: upcoming, symbol: "clock.fill", tint: .blue)
                        }
                        if !fresh.isEmpty {
                            revisionSection(title: "New — not revised yet", items: fresh, symbol: "sparkles", tint: .green)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 720, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            LearnEditSheet()
                .environmentObject(store)
        }
        .sheet(item: $editing) { item in
            LearnEditSheet(existing: item)
                .environmentObject(store)
        }
        .confirmationDialog("Delete this learning item?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = confirmingDelete {
                    store.deleteLearnItem(item.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private func revisionSection(title: String, items: [LearnItem], symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.headline)
                Text("\(items.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ForEach(items) { item in
                LearnItemRow(
                    item: item,
                    onEdit: { editing = item },
                    onDelete: { confirmingDelete = item }
                )
                .environmentObject(store)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Learn")
                    .font(.title.bold())
                Text("\(store.learnItems.count) items · \(store.dueLearnItems.count) due")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip("All", isOn: categoryFilter == nil) { categoryFilter = nil }
            ForEach(store.learnCategories, id: \.self) { category in
                filterChip(category, isOn: categoryFilter == category) {
                    categoryFilter = category
                }
            }
            Spacer()
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
            TextField("Search…", text: $searchText)
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
        .frame(width: 180)
    }
}

// MARK: - Row

struct LearnItemRow: View {
    @EnvironmentObject var store: Store
    let item: LearnItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var expanded = false

    private var dueText: String? {
        guard let next = item.nextRevisionAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        if next <= Date() {
            return "Due \(formatter.localizedString(for: next, relativeTo: Date()))"
        }
        return formatter.localizedString(for: next, relativeTo: Date())
    }

    private var intervalLabel: String {
        guard item.revisionCount > 0 else { return "New" }
        let index = min(item.revisionCount - 1, learnRevisionIntervals.count - 1)
        let days = Int(learnRevisionIntervals[index] / 86400)
        return "R\(item.revisionCount) · \(days)d"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.nextRevisionAt.map { $0 <= Date() } == true ? "exclamationmark.circle.fill" : "book.closed.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(item.nextRevisionAt.map { $0 <= Date() } == true ? .orange : .accentColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        Text(item.category.isEmpty ? "Uncategorized" : item.category)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                        Text(intervalLabel)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.12), in: Capsule())
                        if let dueText {
                            Text(dueText)
                                .font(.caption2)
                                .foregroundStyle(item.nextRevisionAt.map { $0 <= Date() } == true ? .orange : .secondary)
                                .monospacedDigit()
                        }
                        if item.hasVideo {
                            Text("video")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.red)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.red.opacity(0.12), in: Capsule())
                        }
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Button {
                        store.markLearnItemRevised(item.id)
                    } label: {
                        Label("Revised", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .help("Mark revised — schedules the next revision")
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Edit")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
            }

            if expanded {
                Divider()
                if !item.note.isEmpty {
                    Text(markdown(item.note))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
                if item.hasVideo {
                    if let id = youtubeVideoID(from: item.videoURL) {
                        YouTubeEmbedView(videoID: id)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Button {
                            if let u = URL(string: item.videoURL.hasPrefix("http") ? item.videoURL : "https://\(item.videoURL)") {
                                NSWorkspace.shared.open(u)
                            }
                        } label: {
                            Label("Open link", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.link)
                    }
                }
                if let last = item.lastRevisedAt {
                    HStack(spacing: 8) {
                        Text("Last revised \(last.formatted(date: .abbreviated, time: .shortened)) · \(item.revisionCount)x")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        Button {
                            store.resetLearnItemRevision(item.id)
                        } label: {
                            Text("Reset schedule")
                                .font(.caption2)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.nextRevisionAt.map { $0 <= Date() } == true ? Color.orange.opacity(0.5) : Color.gray.opacity(0.14), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { expanded.toggle() }
        .contextMenu {
            Button { expanded.toggle() } label: {
                Label(expanded ? "Collapse" : "Expand", systemImage: expanded ? "chevron.up" : "chevron.down")
            }
            Button {
                store.markLearnItemRevised(item.id)
            } label: {
                Label("Mark revised", systemImage: "checkmark.circle.fill")
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

    private func markdown(_ text: String) -> AttributedString {
        (try? AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(text)
    }
}

// MARK: - Edit sheet

struct LearnEditSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var existing: LearnItem? = nil

    @State private var title = ""
    @State private var videoURL = ""
    @State private var note = ""
    @State private var category = "Uncategorized"
    @State private var newCategory = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(existing == nil ? "Add to Learn" : "Edit")
                .font(.title2.bold())

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Video or link (YouTube…)", text: $videoURL)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 8) {
                Picker("Category", selection: $category) {
                    ForEach(store.learnCategories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .frame(maxWidth: 200)
                TextField("New category", text: $newCategory)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { useNewCategory() }
                Button("Add") { useNewCategory() }
                    .buttonStyle(.bordered)
                    .disabled(newCategory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Text("Notes — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 130)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )

            if let existing {
                HStack(spacing: 8) {
                    Text("Revised \(existing.revisionCount)x")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let next = existing.nextRevisionAt {
                        Text("Next: \(next.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    Button("Reset schedule") {
                        store.resetLearnItemRevision(existing.id)
                    }
                    .buttonStyle(.bordered)
                }
            }

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
        .frame(width: 540)
        .onAppear {
            if let existing {
                title = existing.title
                videoURL = existing.videoURL
                note = existing.note
                category = existing.category.isEmpty ? "Uncategorized" : existing.category
            }
        }
    }

    private func useNewCategory() {
        let trimmed = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        category = trimmed
        newCategory = ""
    }

    private func save() {
        let cat = category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Uncategorized" : category
        if let existing {
            store.updateLearnItem(id: existing.id, title: title, videoURL: videoURL, note: note, category: cat)
        } else {
            store.addLearnItem(title: title, videoURL: videoURL, note: note, category: cat)
        }
        dismiss()
    }
}
