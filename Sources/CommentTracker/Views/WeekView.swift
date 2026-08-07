import SwiftUI
import AppKit

struct WeekView: View {
    @EnvironmentObject var store: Store
    @State private var searchText = ""
    @State private var editingCard: WeekCard?
    @State private var confirmReset = false
    @State private var message = ""

    private var cards: [WeekCard] {
        var list = store.weekCards
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.weekCard($0, matches: searchText) }
        }
        return list.sorted { $0.slot < $1.slot }
    }

    private var filledCount: Int {
        store.weekCards.filter { c in
            !c.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !c.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(cards) { card in
                        WeekCardCell(card: card) {
                            editingCard = card
                        }
                    }
                }
                .padding(16)
            }
        }
        .sheet(item: $editingCard) { card in
            WeekCardEditSheet(card: card) { title, note in
                store.updateWeekCard(id: card.id, title: title, note: note)
            }
            .environmentObject(store)
        }
        .confirmationDialog("Reset the 52-week board?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset — clear all 52", role: .destructive) {
                store.resetWeekCards()
                message = "All 52 weeks cleared"
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears titles and notes for all 52 weeks. Back this up first if you want to keep the current board.")
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("52 Weeks")
                        .font(.title.bold())
                    Text("\(filledCount)/52 filled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Spacer()
                searchField
                if !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Button {
                    exportWeeks()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .help("Export all 52 weeks to a JSON file")
                Button {
                    importWeeks()
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
                .help("Import weeks from a JSON file")
                Button {
                    confirmReset = true
                } label: {
                    Label("Reset", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                .help("Clear all 52 weeks")
            }
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search weeks…", text: $searchText)
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

    private func exportWeeks() {
        guard let json = store.exportWeeks() else { return }
        let panel = NSSavePanel()
        panel.title = "Export 52 Weeks"
        panel.nameFieldStringValue = "52weeks.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func importWeeks() {
        let panel = NSOpenPanel()
        panel.title = "Import 52 Weeks"
        panel.allowedContentTypes = [.json]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let text = try? String(contentsOf: url, encoding: .utf8) else { return }
        let count = store.importWeeks(fromJSON: text)
        message = count > 0 ? "Imported/updated \(count) weeks" : "No weeks imported"
    }
}

// MARK: - Cell

struct WeekCardCell: View {
    @EnvironmentObject var store: Store
    let card: WeekCard
    let onOpenFull: () -> Void

    private var isEmpty: Bool {
        card.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        card.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var renderedNote: AttributedString? {
        let trimmed = card.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            topRow
            if !card.title.isEmpty {
                Text(card.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            if let rendered = renderedNote {
                Text(rendered)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .environment(\.openURL, OpenURLAction { url in
                        NSWorkspace.shared.open(url)
                        return .handled
                    })
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(minHeight: 96, alignment: .topLeading)
        .background(isEmpty ? Color.gray.opacity(0.04) : Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isEmpty ? Color.gray.opacity(0.1) : Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { onOpenFull() }
    }

    private var topRow: some View {
        HStack(spacing: 6) {
            Text("WK \(card.slot)")
                .font(.system(size: 11, weight: .bold))
                .monospacedDigit()
            Text(card.monthName.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(Color.teal.opacity(0.15), in: Capsule())
                .foregroundStyle(.teal)
            Spacer()
            Text(card.dateRangeText)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}

// MARK: - Edit sheet (markdown note + link support)

struct WeekCardEditSheet: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let card: WeekCard
    let onSave: (String, String) -> Void

    @State private var title = ""
    @State private var note = ""

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Week \(card.slot) · \(card.monthName) (\(card.dateRangeText))")
                .font(.title3.bold())
            TextField("Title (optional)", text: $title)
                .textFieldStyle(.roundedBorder)
            Text("Note — markdown supported (e.g. **bold**, - list, [link](https://…), YouTube links)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 180)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            if let rendered = renderedNote, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                    onSave(title, note)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            title = card.title
            note = card.note
        }
    }
}
