import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct BigCardsView: View {
    @EnvironmentObject var store: Store
    @State private var searchText = ""
    @State private var groupFilter = "All"
    @State private var editingCard: BigCard?
    @State private var confirmReset = false
    @State private var message = ""

    private let deckColumns = 40
    private let deckRows = 50
    private let target = 2000

    private var groups: [String] { ["All"] + store.bigCardGroups }

    private var cards: [BigCard] {
        var list = store.bigCards
        if groupFilter != "All" {
            list = list.filter { $0.groupName == groupFilter }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.bigCard($0, matches: searchText) }
        }
        return list.sorted { $0.slot < $1.slot }
    }

    private var filledCount: Int {
        store.bigCards.filter { !$0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                ScrollView(.vertical, showsIndicators: true) {
                    HStack(alignment: .top, spacing: 0) {
                        rowNumberColumn
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.fixed(112), spacing: 4), count: deckColumns),
                            alignment: .leading,
                            spacing: 4
                        ) {
                            ForEach(cards) { card in
                                BigCardCell(card: card) {
                                    editingCard = card
                                }
                            }
                        }
                        .padding(8)
                    }
                }
            }
        }
        .sheet(item: $editingCard) { card in
            EditBigCardView(
                existing: card,
                onSave: { word, group, words, link in
                    store.updateBigCard(id: card.id, word: word, group: group, words: words, link: link)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Reset the 2000-card deck?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset — start a fresh empty deck", role: .destructive) {
                store.resetBigDeck()
                message = "Deck reset to 2000 empty cards"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes all cards and creates a fresh deck of 2000 empty cards (40×50). Back this up first.")
        }
    }

    private var rowNumberColumn: some View {
        VStack(spacing: 4) {
            Spacer().frame(height: 36)
            ForEach(1...deckRows, id: \.self) { r in
                Text("\(r)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .frame(width: 30, height: 56, alignment: .leading)
            }
        }
        .padding(.top, 8)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("2000 Cards")
                        .font(.title.bold())
                    Text("\(filledCount)/2000 filled · 40×50 grid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                searchField
                groupMenu
            }
            HStack(spacing: 10) {
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button {
                    let added = store.addAllEmptyBigCards()
                    message = added > 0 ? "Added \(added) empty cards" : "Deck is already full (2000)"
                } label: {
                    Label("Add 2000 empty", systemImage: "rectangle.stack.badge.plus")
                }
                .buttonStyle(.bordered)
                .help("Top the deck up to 2000 empty cards")
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
                Button {
                    importCards()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
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
        guard let json = store.exportBigCards() else { return }
        let panel = NSSavePanel()
        panel.title = "Export 2000 Cards"
        panel.nameFieldStringValue = "cards2000.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func importCards() {
        let panel = NSOpenPanel()
        panel.title = "Import 2000 Cards"
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        store.importBigCards(fromJSON: text)
    }
}

// MARK: - Cell (compact Excel-style)

struct BigCardCell: View {
    @EnvironmentObject var store: Store
    let card: BigCard
    let onOpenFull: () -> Void

    @State private var text = ""
    @FocusState private var focused: Bool
    @State private var showFull = false

    private var isEmpty: Bool {
        card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            topRow
            wordField
        }
        .padding(5)
        .frame(height: 52, alignment: .topLeading)
        .background(isEmpty ? Color.gray.opacity(0.03) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(focused ? Color.blue.opacity(0.5) : (isEmpty ? Color.gray.opacity(0.1) : Color.gray.opacity(0.16)), lineWidth: focused ? 1.5 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onAppear {
            text = card.word
        }
        .contextMenu {
            Button {
                onOpenFull()
            } label: {
                Label("Edit full card", systemImage: "rectangle.badge.plus")
            }
            Button(role: .destructive) {
                store.deleteBigCard(card.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showFull) {
            EditBigCardView(
                existing: card,
                onSave: { word, group, words, link in
                    store.updateBigCard(id: card.id, word: word, group: group, words: words, link: link)
                }
            )
            .environmentObject(store)
        }
    }

    private var topRow: some View {
        HStack(spacing: 3) {
            Text(cellRef)
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(.tertiary)
            Spacer()
            if hasLink {
                Image(systemName: "link")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
            }
            if wordsCount > 0 {
                Text("+\(wordsCount)")
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var wordField: some View {
        TextField(isEmpty ? "…" : "", text: $text)
            .textFieldStyle(.plain)
            .focused($focused)
            .font(isEmpty ? .caption2.italic() : .caption)
            .foregroundStyle(isEmpty ? .tertiary : .primary)
            .lineLimit(2)
            .onSubmit(commit)
            .onChange(of: focused) { _, new in
                if !new { commit() }
            }
    }

    private var cellRef: String {
        columnLetter(card.col) + "\(card.row)"
    }

    private func columnLetter(_ n: Int) -> String {
        var result = ""
        var value = n
        while value > 0 {
            value -= 1
            result = String(UnicodeScalar(65 + (value % 26))!) + result
            value /= 26
        }
        return result
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
            store.updateBigCard(id: card.id, word: trimmed)
        }
    }
}

// MARK: - Full card dialog

struct EditBigCardView: View {
    @Environment(\.dismiss) private var dismiss
    var existing: BigCard? = nil
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
                Text("Cell \(existing.slot) of 2000")
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
