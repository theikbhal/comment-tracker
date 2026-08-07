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
        return list.sorted {
            let a = $0.groupName.lowercased(), b = $1.groupName.lowercased()
            if a == b { return $0.word.localizedCaseInsensitiveCompare($1.word) == .orderedAscending }
            return a < b
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    ForEach(cards) { card in
                        CardCell(card: card) {
                            editingCard = card
                        }
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAdd) {
            EditWordCardView(
                onSave: { store.addCard(word: $0, group: $1, words: $2, link: $3) }
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
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("313 Cards")
                    .font(.title.bold())
                Text("\(store.cards.count) cards · each one a word")
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
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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
            .help("Export all cards to a JSON file")
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

// MARK: - Cell

struct CardCell: View {
    @EnvironmentObject var store: Store
    let card: WordCard
    let onOpen: () -> Void

    private var wordsCount: Int {
        card.words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Empty card")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(card.word)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 5) {
                if !card.groupName.isEmpty {
                    Text(card.groupName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                        .foregroundStyle(.blue)
                }
                Spacer()
                if !card.link.isEmpty { Image(systemName: "link").font(.caption2).foregroundStyle(.tertiary) }
                if wordsCount > 0 { Text("+\(wordsCount)").font(.caption2).foregroundStyle(.secondary) }
            }
        }
        .padding(12)
        .frame(minHeight: 74, alignment: .leading)
        .background(
            card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? Color.gray.opacity(0.04)
                : Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(card.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.1) : Color.gray.opacity(0.15), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture {
            onOpen()
        }
        .contextMenu {
            Button { onOpen() } label: { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) {
                store.deleteCard(card.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add / Edit

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
                .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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