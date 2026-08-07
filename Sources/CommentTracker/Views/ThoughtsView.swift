import SwiftUI
import AppKit

private struct ThoughtCardTopKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] { [:] }
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

struct ThoughtsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var pickedThought: Thought?

    private var matchedCount: Int {
        store.thoughts.filter { store.thought($0, matches: searchText) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ThoughtBoardView(searchText: searchText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingAdd) {
            AddThoughtsView()
                .environmentObject(store)
        }
        .sheet(item: $pickedThought) { thought in
            PickForMeView(thought: thought) { picked in
                pickedThought = picked
            }
            .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Thoughts")
                    .font(.title.bold())
                Text("\(store.thoughts.count) saved — don't lose a good idea")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\(matchedCount) found")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Button {
                guard let t = store.randomActiveThought() else { return }
                pickedThought = t
            } label: {
                Label("Pick for me", systemImage: "dice.fill")
            }
            .buttonStyle(.bordered)
            .help("Can't decide what to do next? Let the dice pick a thought.")
            .disabled(store.thoughts.isEmpty)
            Button {
                showingAdd = true
            } label: {
                Label("Add Thoughts", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search thoughts…", text: $searchText)
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
}

// MARK: - Board

struct ThoughtBoardView: View {
    @EnvironmentObject var store: Store
    let searchText: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(ThoughtList.allCases) { list in
                    ThoughtColumnView(list: list, searchText: searchText)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Column

struct ThoughtColumnView: View {
    @EnvironmentObject var store: Store
    let list: ThoughtList
    let searchText: String

    @State private var isDropTargeted = false
    @State private var cardTops: [Int: CGFloat] = [:]

    private var columnSpaceName: String { "thoughtcol-\(list.rawValue)" }
    private var thoughts: [Thought] {
        store.thoughtsForList(list).filter { store.thought($0, matches: searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(thoughts) { thought in
                        ThoughtCardView(thought: thought, list: list)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: ThoughtCardTopKey.self,
                                        value: [thought.id: geo.frame(in: .named(columnSpaceName)).minY]
                                    )
                                }
                            )
                    }
                    if thoughts.isEmpty {
                        emptyHint
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 232)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(list.color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDropTargeted ? list.color : Color.gray.opacity(0.14), lineWidth: isDropTargeted ? 2 : 1)
        )
        .coordinateSpace(name: columnSpaceName)
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers, location in
            handleDrop(providers, location: location)
        }
        .onPreferenceChange(ThoughtCardTopKey.self) { value in
            cardTops = value
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: list.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(list.color)
                Text(list.displayName)
                    .font(.headline)
                Spacer()
                Text("\(thoughts.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(list == .doing ? "what you're focusing on" : (list == .thisWeek ? "act on within 7 days" : "someday, don't lose them"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 4)
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Image(systemName: list.symbol)
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text("Drag cards here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .contentShape(Rectangle())
    }

    private func handleDrop(_ providers: [NSItemProvider], location: CGPoint) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? String, let id = Int(idString) else { return }
            Task { @MainActor in
                let index = self.insertionIndex(for: location.y)
                self.store.moveThought(id, to: self.list, at: index)
            }
        }
        return true
    }

    private func insertionIndex(for locationY: CGFloat) -> Int {
        var index = thoughts.count
        for (i, t) in thoughts.enumerated() {
            if let top = cardTops[t.id], top > locationY {
                index = i
                break
            }
        }
        return index
    }
}

// MARK: - Card

struct ThoughtCardView: View {
    @EnvironmentObject var store: Store
    @State private var editing = false
    let thought: Thought
    let list: ThoughtList

    private var noteCount: Int {
        thought.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                if list == .doing {
                    Image(systemName: "person.fill.checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(list.color.gradient, in: RoundedRectangle(cornerRadius: 5))
                }
                Text(thought.title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .strikethrough(false)
                Spacer()
            }
            if !thought.note.isEmpty {
                Text(thought.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 8) {
                Text(thought.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                if list != .doing {
                    Button {
                        store.updateThought(id: thought.id, list: .doing)
                    } label: {
                        Image(systemName: "arrow.up.to.line")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Start doing this")
                }
                Button {
                    editing = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .help("Edit")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(list.color)
                .frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .contextMenu {
            if list != .doing {
                Button {
                    store.updateThought(id: thought.id, list: .doing)
                } label: {
                    Label("Start doing", systemImage: "arrow.up.to.line")
                }
            }
            Button {
                store.updateThought(id: thought.id, note: thought.note.isEmpty ? thought.title : "")
            } label: {
                Label(thought.note.isEmpty ? "Add a note" : "Clear note", systemImage: "note.text")
            }
            Divider()
            Button(role: .destructive) {
                store.deleteThought(thought.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onTapGesture(count: 2) {
            editing = true
        }
        .onDrag {
            return NSItemProvider(object: "\(thought.id)" as NSString)
        }
        .sheet(isPresented: $editing) {
            EditThoughtView(thoughtID: thought.id)
                .environmentObject(store)
        }
    }
}

// MARK: - Edit Thought

struct EditThoughtView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let thoughtID: Int

    @State private var title = ""
    @State private var note = ""
    @State private var list: ThoughtList = .longTerm

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Thought")
                .font(.title2.bold())
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Note (why it matters, context…)", text: $note)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 6) {
                Text("List")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("List", selection: $list) {
                    ForEach(ThoughtList.allCases) { l in
                        Text(l.displayName).tag(l)
                    }
                }
                .labelsHidden()
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button(role: .destructive) {
                    store.deleteThought(thoughtID)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button {
                    store.updateThought(id: thoughtID, title: title, note: note, list: list)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            guard let t = store.thoughtByID(thoughtID) else { return }
            title = t.title
            note = t.note
            list = t.list
        }
    }
}

// MARK: - Bulk / Single Add

struct AddThoughtsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var text = ""
    @State private var list: ThoughtList = .longTerm

    private var count: Int {
        text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Thoughts")
                .font(.title2.bold())
            Text("One idea per line — add a single thought or paste a whole batch.")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                .frame(height: 180)
            if count > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "list.bullet")
                        .font(.caption)
                    Text("\(count) thought\(count == 1 ? "" : "s") ready")
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Add to list")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("List", selection: $list) {
                    ForEach(ThoughtList.allCases) { l in
                        Text(l.displayName).tag(l)
                    }
                }
                .labelsHidden()
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    let lines = text.split(separator: "\n").map { String($0) }
                    store.addThoughts(lines, list: list)
                    dismiss()
                } label: {
                    Label("Add Thoughts", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(count == 0)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}

// MARK: - Pick for me

struct PickForMeView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let thought: Thought
    let onShuffle: (Thought?) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: listSymbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(listColor)
                .frame(width: 64, height: 64)
                .background(listColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            VStack(spacing: 4) {
                Text("Start with this one")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(thought.title)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                if !thought.note.isEmpty {
                    Text(thought.note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            HStack {
                Button {
                    onShuffle(store.randomActiveThought())
                } label: {
                    Label("Shuffle again", systemImage: "dice")
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("r", modifiers: .command)
                Spacer()
                Button("Cancel") { dismiss() }
                Button {
                    store.updateThought(id: thought.id, list: .doing)
                    dismiss()
                } label: {
                    Label("Do it now", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 380)
    }

    private var listColor: Color {
        thought.list == .doing ? Color.orange : thought.list.color
    }

    private var listSymbol: String {
        thought.list == .doing ? "bolt.fill" : thought.list.symbol
    }
}