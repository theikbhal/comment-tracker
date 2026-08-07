import SwiftUI
import AppKit
import UniformTypeIdentifiers

private let urgentLaneWidth: CGFloat = 280

struct UrgentView: View {
    @EnvironmentObject var store: Store
    @State private var composeDrafts: [Int: String] = [:]
    @State private var showAddSheet: Urgency?
    @State private var editingItem: UrgentItem?

    private var openCount: Int {
        store.urgent.filter { !$0.done }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(allUrgencies) { urgency in
                        urgencyLane(urgency)
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $showAddSheet) { urgency in
            UrgentEditSheet(urgency: urgency)
                .environmentObject(store)
        }
        .sheet(item: $editingItem) { item in
            UrgentEditSheet(item: item)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Urgent")
                    .font(.title.bold())
                Text("\(store.urgent.count) urgent · \(openCount) open")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Button {
                showAddSheet = .now
            } label: {
                Label("Add urgent", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .padding(16)
    }

    private func urgencyLane(_ urgency: Urgency) -> some View {
        let items = store.urgentItems(for: urgency)
        let color = urgency.color
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: urgency.symbol)
                    .font(.subheadline)
                    .foregroundStyle(color)
                Text(urgency.label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(items.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button {
                    showAddSheet = urgency
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(color)
                }
                .buttonStyle(.plain)
                .help("Add to \(urgency.label)")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    UrgentCardView(item: item) {
                        editingItem = item
                    }
                    .onDrop(of: [UTType.text.identifier], delegate: UrgentCardDropDelegate(store: store, lane: urgency, index: index))
                }
                if items.isEmpty {
                    Text("Nothing here yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                HStack(spacing: 6) {
                    TextField("Add to \(urgency.label)…", text: binding(for: urgency))
                        .textFieldStyle(.plain)
                        .onSubmit { add(urgency) }
                    Button {
                        add(urgency)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
                .padding(6)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .onDrop(of: [UTType.text.identifier], delegate: UrgentLaneDropDelegate(store: store, lane: urgency))
        }
        .frame(width: urgentLaneWidth, alignment: .top)
        .padding(8)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func binding(for urgency: Urgency) -> Binding<String> {
        Binding(
            get: { composeDrafts[urgency.rawValue] ?? "" },
            set: { composeDrafts[urgency.rawValue] = $0 }
        )
    }

    private func add(_ urgency: Urgency) {
        let trimmed = (composeDrafts[urgency.rawValue] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addUrgent(text: trimmed, urgency: urgency)
        composeDrafts[urgency.rawValue] = ""
    }
}

struct UrgentCardView: View {
    @EnvironmentObject var store: Store
    let item: UrgentItem
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    store.toggleUrgentDone(item.id)
                } label: {
                    Image(systemName: item.done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.done ? item.urgency.color : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(item.done ? "Mark not done" : "Mark done")

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.text)
                        .font(.subheadline.weight(.semibold))
                        .textSelection(.enabled)
                        .strikethrough(item.done, color: .secondary)
                        .opacity(item.done ? 0.55 : 1)
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .textSelection(.enabled)
                    }
                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(item.done ? Color.gray.opacity(0.15) : item.urgency.color.opacity(0.45), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onDrag {
            NSItemProvider(object: String(item.id) as NSString)
        }
        .contextMenu {
            Button {
                store.toggleUrgentDone(item.id)
            } label: {
                Label(item.done ? "Mark not done" : "Mark done", systemImage: item.done ? "checkmark.circle" : "checkmark.circle.fill")
            }
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Divider()
            ForEach(allUrgencies) { urgency in
                if urgency != item.urgency {
                    Button {
                        store.moveUrgent(item.id, to: urgency, at: store.urgentItems(for: urgency).count)
                    } label: {
                        Label("Move to \(urgency.label)", systemImage: "arrow.right")
                    }
                }
            }
            Divider()
            Button(role: .destructive) {
                store.deleteUrgent(item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct UrgentCardDropDelegate: DropDelegate {
    let store: Store
    let lane: Urgency
    let index: Int

    func dropEntered(info: DropInfo) {}
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [UTType.text.identifier]).first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let id = Int(String(data: data, encoding: .utf8) ?? "") {
                DispatchQueue.main.async {
                    store.moveUrgent(id, to: lane, at: index)
                }
            }
        }
        return true
    }
}

struct UrgentLaneDropDelegate: DropDelegate {
    let store: Store
    let lane: Urgency

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [UTType.text.identifier]).first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let id = Int(String(data: data, encoding: .utf8) ?? "") {
                DispatchQueue.main.async {
                    store.moveUrgent(id, to: lane, at: store.urgentItems(for: lane).count)
                }
            }
        }
        return true
    }
}

// MARK: - Add / Edit sheet (section picker popup)

struct UrgentEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let item: UrgentItem?

    @State private var text: String
    @State private var note: String
    @State private var urgency: Urgency

    init(urgency: Urgency) {
        self.item = nil
        _text = State(initialValue: "")
        _note = State(initialValue: "")
        _urgency = State(initialValue: urgency)
    }

    init(item: UrgentItem) {
        self.item = item
        _text = State(initialValue: item.text)
        _note = State(initialValue: item.note)
        _urgency = State(initialValue: item.urgency)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(item == nil ? "Add urgent" : "Edit urgent")
                .font(.headline)
            TextField("What's urgent?", text: $text)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $note)
                .font(.body)
                .frame(minHeight: 90)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                Text("Pick a section")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Section", selection: $urgency) {
                    ForEach(allUrgencies) { u in
                        Label(u.label, systemImage: u.symbol).tag(u)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(urgency.color)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(item == nil ? "Add" : "Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(urgency.color)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420, height: 330)
    }

    private func save() {
        if let item {
            store.updateUrgent(id: item.id, text: text, note: note, urgency: urgency)
        } else {
            store.addUrgent(text: text, urgency: urgency, note: note)
        }
        dismiss()
    }
}
