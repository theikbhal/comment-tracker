import SwiftUI
import AppKit

struct RoadmapView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: RoadmapItem?

    private var totalCount: Int { store.roadmap.count }
    private var doneCount: Int { store.roadmapItems(for: .done).count }

    private func cards(for status: RoadmapStatus) -> [RoadmapItem] {
        store.roadmapItems(for: status).filter { store.roadmapItem($0, matches: searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(RoadmapStatus.allCases) { status in
                        roadmapColumn(status)
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAdd) {
            RoadmapEditSheet { title, body, quarter, priority in
                store.addRoadmapItem(title: title, body: body, status: .planned, quarter: quarter, priority: priority)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { item in
            RoadmapEditSheet(
                existing: item,
                onSave: { title, body, quarter, priority in
                    store.updateRoadmapItem(id: item.id, title: title, body: body, quarter: quarter, priority: priority)
                }
            )
            .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Roadmap")
                    .font(.title.bold())
                Text("\(doneCount)/\(totalCount) done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search roadmap…", text: $searchText)
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

    private func roadmapColumn(_ status: RoadmapStatus) -> some View {
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
                    ForEach(items) { item in
                        RoadmapCardView(item: item) {
                            editing = item
                        }
                    }
                    if items.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: status.symbol)
                                .font(.system(size: 22))
                                .foregroundStyle(.tertiary)
                            Text("Nothing here")
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

struct RoadmapCardView: View {
    @EnvironmentObject var store: Store
    let item: RoadmapItem
    let onOpenFull: () -> Void

    private var renderedBody: AttributedString? {
        let trimmed = item.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: item.status.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(item.status.color.gradient, in: RoundedRectangle(cornerRadius: 6))
                Text(item.title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
                statusMenu
            }
            HStack(spacing: 6) {
                if !item.quarter.isEmpty {
                    Text(item.quarter)
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }
                Text(item.priority.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(item.priority.color.opacity(0.14), in: Capsule())
                    .foregroundStyle(item.priority.color)
                Spacer()
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
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(item.priority.color)
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
                Label("Edit item…", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                store.deleteRoadmapItem(item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(RoadmapStatus.allCases) { s in
                Button {
                    store.setRoadmapStatus(id: item.id, status: s)
                } label: {
                    if s == item.status {
                        Label(s.displayName, systemImage: "checkmark")
                    } else {
                        Text(s.displayName)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 13))
                .foregroundStyle(item.status.color)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Move to another status")
    }
}

// MARK: - Edit sheet

struct RoadmapEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: RoadmapItem? = nil
    let onSave: (String, String, String, RoadmapPriority) -> Void

    @State private var title = ""
    @State private var note = ""
    @State private var quarter = ""
    @State private var priority: RoadmapPriority = .medium

    private var renderedBody: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Roadmap Item" : "Edit Roadmap Item")
                .font(.title2.bold())
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 10) {
                TextField("Quarter (e.g. Q3 2026)", text: $quarter)
                    .textFieldStyle(.roundedBorder)
                Picker("Priority", selection: $priority) {
                    ForEach(RoadmapPriority.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }
                .labelsHidden()
            }
            Text("Note — markdown supported ([link](https://…), **bold**, lists)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 150)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            if let rendered = renderedBody, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                    onSave(title, note, quarter, priority)
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
        .frame(width: 460)
        .onAppear {
            if let existing {
                title = existing.title
                note = existing.body
                quarter = existing.quarter
                priority = existing.priority
            }
        }
    }
}
