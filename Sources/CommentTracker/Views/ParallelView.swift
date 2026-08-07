import SwiftUI
import AppKit
import UniformTypeIdentifiers

private let parallelLanes: [Int] = [0, 1, 2, 3]

func laneLabel(_ lane: Int) -> String {
    switch lane {
    case 1: return "Thing 2"
    case 2: return "Thing 3"
    case 3: return "Unorganized"
    default: return "Thing 1"
    }
}

func laneColor(_ lane: Int) -> Color {
    switch lane {
    case 0: return .blue
    case 1: return .green
    case 2: return .purple
    default: return .gray
    }
}

struct ParallelView: View {
    @EnvironmentObject var store: Store
    @State private var drafts: [Int: String] = [:]
    @State private var showTextSheet: ParallelItem?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(parallelLanes, id: \.self) { lane in
                        laneColumn(lane)
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $showTextSheet) { item in
            ParallelEditSheet(item: item)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Parallel")
                    .font(.title.bold())
                Text("3 threads + a catch-all for the unorganized")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(store.parallel.count) items")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(16)
    }

    private func laneColumn(_ lane: Int) -> some View {
        let items = store.parallel.filter { $0.lane == lane }
        let color = laneColor(lane)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(laneLabel(lane))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(items.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

            VStack(spacing: 8) {
                ForEach(items) { item in
                    ParallelCardView(item: item) {
                        showTextSheet = item
                    }
                }
                HStack(spacing: 6) {
                    TextField("Add…", text: binding(for: lane))
                        .textFieldStyle(.plain)
                        .onSubmit { add(lane) }
                    Button {
                        add(lane)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
                .padding(6)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .background(color.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
            .onDrop(of: [UTType.text.identifier], delegate: ParallelDropDelegate(store: store, lane: lane))
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .padding(8)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }

    private func binding(for lane: Int) -> Binding<String> {
        Binding(
            get: { drafts[lane] ?? "" },
            set: { drafts[lane] = $0 }
        )
    }

    private func add(_ lane: Int) {
        let trimmed = (drafts[lane] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addParallelItem(lane: lane, text: trimmed)
        drafts[lane] = ""
    }
}

struct ParallelCardView: View {
    @EnvironmentObject var store: Store
    let item: ParallelItem
    var onEdit: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.text)
                .font(.subheadline.weight(.semibold))
                .textSelection(.enabled)
            if !item.note.isEmpty {
                Text(item.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.15), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onDrag {
            NSItemProvider(object: String(item.id) as NSString)
        }
        .contextMenu {
            Button { onEdit?() } label: { Label("Edit note", systemImage: "pencil") }
            Divider()
            ForEach(parallelLanes, id: \.self) { lane in
                Button {
                    store.moveParallelItem(item.id, to: lane)
                } label: {
                    Label("Move to \(laneLabel(lane))", systemImage: "arrow.right")
                }
            }
            Divider()
            Button(role: .destructive) {
                store.deleteParallelItem(item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct ParallelDropDelegate: DropDelegate {
    let store: Store
    let lane: Int

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [UTType.text.identifier]).first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
            if let data = item as? Data,
               let id = Int(String(data: data, encoding: .utf8) ?? "") {
                DispatchQueue.main.async {
                    store.moveParallelItem(id, to: lane)
                }
            }
        }
        return true
    }
}

struct ParallelEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let item: ParallelItem
    @State private var note: String

    init(item: ParallelItem) {
        self.item = item
        _note = State(initialValue: item.note)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit — \(item.text)")
                .font(.headline)
            TextEditor(text: $note)
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
                    store.updateParallelNote(item.id, note: note)
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