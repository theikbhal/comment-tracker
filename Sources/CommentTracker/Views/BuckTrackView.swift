import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BuckTrackView: View {
    @EnvironmentObject var store: Store
    @State private var newTitle = ""
    @State private var searchText = ""
    @State private var editingBuck: Buck?

    private var all: [Buck] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = q.isEmpty ? store.bucks : store.bucks.filter { store.buck($0, matches: searchText) }
        return base.sorted {
            if $0.status.sortOrder == $1.status.sortOrder { return $0.updatedAt > $1.updatedAt }
            return $0.status.sortOrder < $1.status.sortOrder
        }
    }

    private func group(_ status: BuckStatus) -> [Buck] {
        all.filter { $0.status == status }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            addBar
                .padding(.horizontal, 16)
                .padding(.top, 12)
            searchRow
                .padding(.horizontal, 16)
                .padding(.top, 8)
            Divider()
                .padding(.top, 12)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        columnsRow
                    } else {
                        searchResults
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $editingBuck) { buck in
            EditBuckSheet(buck: buck)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Buck Track")
                    .font(.title.bold())
                Text("\(store.buckActiveCount("")) in flight")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Text("\(store.bucks.count) buckets total")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    private var addBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
            TextField("What are we working on?", text: $newTitle)
                .textFieldStyle(.plain)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Add to In Flight")
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
    }

    private var searchRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search buckets…", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: 260)
    }

    private var columnsRow: some View {
        HStack(alignment: .top, spacing: 14) {
            ForEach(BuckStatus.allCases, id: \.self) { status in
                column(status)
            }
        }
    }

    private var searchResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search results")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(all) { buck in
                HStack {
                    BuckCardView(buck: buck)
                    Spacer()
                }
                .frame(maxWidth: 420, alignment: .leading)
            }
            if all.isEmpty {
                Text("No buckets match")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            }
        }
    }

    private func column(_ status: BuckStatus) -> some View {
        let items = group(status)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: status.symbol)
                    .font(.caption)
                    .foregroundStyle(status.color)
                Text(status.displayName)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(items.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(status.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 8) {
                if items.isEmpty {
                    Text("Drop here")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .padding(.vertical, 10)
                } else {
                    ForEach(items) { buck in
                        BuckCardView(buck: buck) { editingBuck = buck }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
            .onDrop(of: [UTType.text.identifier], delegate: BuckDropDelegate(store: store, status: status))
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(8)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func add() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addBuck(title: trimmed, notes: "")
        newTitle = ""
    }
}

private extension BuckStatus {
    var sortOrder: Int {
        switch self { case .active: return 0; case .paused: return 1; case .done: return 2 }
    }
}

struct BuckDropDelegate: DropDelegate {
    let store: Store
    let status: BuckStatus

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [UTType.text.identifier]).first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let id = Int(String(data: data, encoding: .utf8) ?? "") {
                DispatchQueue.main.async {
                    store.setBuckStatus(id, status)
                }
            }
        }
        return true
    }
}

struct BuckCardView: View {
    @EnvironmentObject var store: Store
    let buck: Buck
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(buck.title)
                .font(.subheadline.weight(.semibold))
                .textSelection(.enabled)
            if !buck.notes.isEmpty {
                Text(buck.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
            HStack(spacing: 6) {
                Image(systemName: buck.status.symbol)
                    .font(.system(size: 9))
                Text(buck.status.displayName)
                    .font(.caption2)
            }
            .foregroundStyle(buck.status.color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(buck.status.color.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(buck.status.color.opacity(0.25), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onDrag {
            let provider = NSItemProvider(object: String(buck.id) as NSString)
            return provider
        }
        .contextMenu {
            Button { store.setBuckStatus(buck.id, .active) } label: { Label("In Flight", systemImage: "bolt.fill") }
            Button { store.setBuckStatus(buck.id, .paused) } label: { Label("On Hold", systemImage: "pause.fill") }
            Button { store.setBuckStatus(buck.id, .done) } label: { Label("Done", systemImage: "checkmark.seal") }
            Button { onEdit?() } label: { Label("Edit notes", systemImage: "pencil") }
            Divider()
            Button { store.deleteBuck(buck.id) } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

// MARK: - Edit notes

struct EditBuckSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let buck: Buck
    @State private var notes: String

    init(buck: Buck) {
        self.buck = buck
        _notes = State(initialValue: buck.notes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit — \(buck.title)")
                .font(.headline)
            TextEditor(text: $notes)
                .font(.body)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    store.updateBuckNote(buck.id, notes: notes)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 440, height: 320)
    }
}