import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct Cards313View: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var groupFilter = "All"
    @State private var editingCard: WordCard?
    @State private var confirmReset = false
    @State private var hideEmpty = false
    @State private var message = ""

    private let deckColumns = 10

    private var groups: [String] { ["All"] + store.cardGroups }

    private var cards: [WordCard] {
        var list = store.cards
        if groupFilter != "All" {
            list = list.filter { $0.groupName == groupFilter }
        }
        if hideEmpty {
            list = list.filter { !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.card($0, matches: searchText) }
        }
        return list.sorted { $0.slot < $1.slot }
    }

    private var filledCount: Int {
        store.cards.filter { !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var visibleCount: Int {
        hideEmpty || !searchText.isEmpty || groupFilter != "All" ? cards.count : store.cards.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(118), spacing: 8), count: deckColumns),
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(cards) { card in
                            Card313Cell(card: card) {
                                editingCard = card
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            EditWordCardView(
                onSave: { word, group, words, link in
                    store.addCard(word: word, group: group, words: words, link: link)
                }
            )
        }
        .sheet(item: $editingCard) { card in
            EditWordCardView(
                existing: card,
                onSave: { word, group, words, link in
                    store.updateCard(id: card.id, word: word, group: group, words: words, link: link)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Reset the 313-card deck?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset — start a fresh empty deck", role: .destructive) {
                store.resetDeck()
                message = "Deck reset to 313 empty cards"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes all cards and creates a fresh deck of 313 empty cards. Back this up first if you want to keep the current deck.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("313 Cards")
                        .font(.title.bold())
                    Text("\(filledCount)/313 filled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                searchField
                groupMenu
                Toggle(isOn: $hideEmpty) {
                    Label("Hide empty", systemImage: "eye.slash")
                        .font(.caption)
                }
                .toggleStyle(.checkbox)
                .help("Hide empty cards")
            }
            HStack(spacing: 10) {
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                deckButtons
            }
        }
        .padding(16)
    }

    private var deckButtons: some View {
        HStack(spacing: 8) {
            Button {
                let added = store.addAllEmptyCards()
                message = added > 0 ? "Added \(added) empty cards" : "Deck is already full (313)"
            } label: {
                Label("Add 313 empty", systemImage: "rectangle.stack.badge.plus")
            }
            .buttonStyle(.bordered)
            .help("Top the deck up to 313 empty cards")
            Button {
                confirmReset = true
            } label: {
                Label("Reset", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(.red)
            .help("Delete all cards and start a fresh empty deck")
            Button {
                exportCards()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)
            .help("Export all -tips to file")
            Button {
                importCards()
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(.bordered)
            .help("Import cards from a JSON file")
            Button {
                showingAdd = true
            } label: {
                Label("Add Card", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search word or group…", text: $searchText)
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
        .frame(width: 220)
    }

    private var groupMenu: some View {
        Menu {
            ForEach(groups, id: \.self) { group in
                Button {
                    groupFilter = group
                } label: {
                    if group == groupFilter {
                        Label(group.isEmpty ? "Ungrouped" : group, systemImage: "checkmark")
                    } else {
                        Text(group.isEmpty ? "Ungrouped" : group)
                    }
                }
            }
        } label: {
            Label(groupFilter.isEmpty ? "All groups" : groupFilter, systemImage: "rectangle.3.group")
        }
    }

    private func exportCards() {
        guard let json = store.exportCards() else { return }
        let panel = NSSavePanel()
        panel.title = "Export 313 Cards"
        panel.nameFieldStringValue = "cards313.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func importCards() {
        let panel = NSOpenPanel()
        panel.title = "Import 313 Cards"
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        store.importCards(fromJSON: text)
    }
}

// MARK: - Cell (in-place editable)

struct Card313Cell: View {
    @EnvironmentObject var store: Store
    let card: WordCard
    let onOpenFull: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var showFull = false

    private var isEmpty: Bool {
        card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            topRow
            wordField
            bottomRow
        }
        .padding(8)
        .frame(height: 74, alignment: .topLeading)
        .background(isEmpty ? Color.gray.opacity(0.04) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(focused ? Color.blue.opacity(0.5) : (isEmpty ? Color.gray.opacity(0.1) : Color.gray.opacity(0.16)), lineWidth: focused ? 1.5 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onAppear {
            text = card.word
        }
        .contextMenu {
            Button {
                onOpenFull()
            } label: {
                Label("Edit full card (5 words + link)", systemImage: "rectangle.badge.plus")
            }
            Button(role: .destructive) {
                store.deleteCard(card.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showFull) {
            EditWordCardView(
                existing: card,
                onSave: { word, group, words, link in
                    store.updateCard(id: card.id, word: word, group: group, words: words, link: link)
                }
            )
            .environmentObject(store)
        }
    }

    private var topRow: some View {
        HStack(spacing: 4) {
            Text("\(card.slot)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Spacer()
            if hasLink {
                Image(systemName: "link")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
            if wordsCount > 0 {
                Text("+\(wordsCount)")
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var wordField: some View {
        TextField(isEmpty ? "Empty card" : "", text: $text)
            .textFieldStyle(.plain)
            .focused($focused)
            .font(isEmpty ? .callout.italic() : .headline)
            .foregroundStyle(isEmpty ? .tertiary : .primary)
            .lineLimit(2)
            .onSubmit(commit)
            .onChange(of: focused) { _, new in
                if !new { commit() }
            }
    }

    private var bottomRow: some View {
        HStack(spacing: 4) {
            if !card.groupName.isEmpty {
                Text(card.groupName)
                    .font(.system(size: 8, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
            Spacer()
            Text("r\(card.row) c\(card.col)")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }

    private var wordsCount: Int {
        card.words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    private var hasLink: Bool {
        !card.link.isEmpty
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed != card.word {
            store.updateCard(id: card.id, word: trimmed)
        }
    }
}
// MARK: - Full card dialog (5 words + link)

struct EditWordCardView: View {
    @Environment(\.dismiss) private var dismiss
    var existing: WordCard? = nil
    let onSave: (String, String, [String], String) -> Void

    @State private var word = ""
    @State private var group = ""
    @State private var wordFields: [String] = Array(repeating: "", count: 5)
    @State private var link = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(existing == nil ? "Add Card" : "Edit Card")
                .font(.title2.bold())
            if let existing {
                Text("Slot \(existing.slot)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Word")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("One word", text: $word)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Group name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Group (searchable by this)", text: $group)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("5 related words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(0..<5, id: \.self) { i in
                    TextField("Word \(i + 1)", text: $wordFields[i])
                        .textFieldStyle(.roundedBorder)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Link (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("URL", text: $link)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(word, group, wordFields, link)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && existing == nil)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            if let existing {
                word = existing.word
                group = existing.groupName
                link = existing.link
                for (i, w) in existing.words.enumerated() where i < 5 {
                    wordFields[i] = w
                }
            }
        }
    }
}
