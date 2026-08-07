import SwiftUI
import AppKit

struct LinksView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""

    private var links: [LinkItem] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return store.links }
        return store.links.filter { store.link($0, matches: searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if links.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(links) { link in
                        LinkRowView(link: link)
                            .onDrag { NSItemProvider(object: "\(link.id)" as NSString) }
                            .onDrop(of: [.text], delegate: LinkDropDelegate(id: link.id, links: links, store: store))
                    }
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddLinkView()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Links")
                    .font(.title.bold())
                Text("\(store.links.count) saved links")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Link", systemImage: "link.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search links…", text: $searchText)
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "link")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No links yet — save your first one")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private struct LinkDropDelegate: DropDelegate {
    let id: Int
    let links: [LinkItem]
    let store: Store

    func dropEntered(info: DropInfo) {
        guard let source = info.itemProviders(for: [.text]).first else { return }
        _ = source.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? String, let sourceID = Int(idString), sourceID != id else { return }
            Task { @MainActor in
                guard let targetIndex = links.firstIndex(where: { $0.id == id }) else { return }
                store.moveLink(sourceID, to: targetIndex)
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool { true }
}

// MARK: - Row

struct LinkRowView: View {
    @EnvironmentObject var store: Store
    @State private var editing = false
    let link: LinkItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue.gradient, in: RoundedRectangle(cornerRadius: 6))
            VStack(alignment: .leading, spacing: 1) {
                Text(link.label.isEmpty ? link.url : link.label)
                    .font(.subheadline.weight(.semibold))
                Text(link.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(link.createdAt.formatted(date: .numeric, time: .omitted))
                .font(.caption2)
                .foregroundStyle(.tertiary)
            Image(systemName: "arrow.up.arrow.down")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            editing = true
        }
        .onTapGesture {
            if let url = URL(string: link.url.contains("://") ? link.url : "https://\(link.url)") {
                NSWorkspace.shared.open(url)
            }
        }
        .contextMenu {
            Button {
                editing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                store.deleteLink(link.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $editing) {
            EditLinkView(link: link)
                .environmentObject(store)
        }
    }
}

// MARK: - Add / Edit

struct AddLinkView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var url = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Link")
                .font(.title2.bold())
            TextField("Label (optional)", text: $label)
                .textFieldStyle(.roundedBorder)
            TextField("URL — x.com/…, youtube.com/…", text: $url)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    store.addLink(label: label, url: url)
                    dismiss()
                } label: {
                    Label("Add", systemImage: "link.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

struct EditLinkView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let link: LinkItem
    @State private var label = ""
    @State private var url = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Link")
                .font(.title2.bold())
            TextField("Label (optional)", text: $label)
                .textFieldStyle(.roundedBorder)
            TextField("URL", text: $url)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(role: .destructive) {
                    store.deleteLink(link.id)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    store.updateLink(id: link.id, label: label, url: url)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            label = link.label
            url = link.url
        }
    }
}