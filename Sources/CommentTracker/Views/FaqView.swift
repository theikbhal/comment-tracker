import SwiftUI
import AppKit

struct FaqView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: Faq?
    @State private var confirmingDelete: Faq?
    @State private var expandedID: Int?
    @State private var editingEntry: FaqEntry?
    @State private var confirmingDeleteEntry: FaqEntry?
    @State private var addingEntryTo: Faq?

    private var faqs: [Faq] {
        var list = store.faqs
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.faq($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if faqs.isEmpty {
                        Text("No FAQs yet. Paste a YouTube link, then paste the FAQ ChatGPT wrote from the video — Q1., Q2., … rows become questions and answers.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(faqs) { faq in
                        FaqCard(
                            faq: faq,
                            isExpanded: expandedID == faq.id,
                            onToggleExpand: {
                                expandedID = expandedID == faq.id ? nil : faq.id
                            },
                            onEdit: { editing = faq },
                            onDelete: { confirmingDelete = faq },
                            onMoveUp: { store.moveFaq(id: faq.id, direction: -1) },
                            onMoveDown: { store.moveFaq(id: faq.id, direction: 1) },
                            onAddEntry: { addingEntryTo = faq },
                            onEditEntry: { editingEntry = $0 },
                            onDeleteEntry: { confirmingDeleteEntry = $0 }
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            FaqEditSheet { title, url, pasted in
                store.addFaq(title: title, youtubeURL: url, pastedFAQ: pasted)
            }
        }
        .sheet(item: $editing) { faq in
            FaqEditSheet(title: faq.title, youtubeURL: faq.youtubeURL) { title, url, _ in
                store.updateFaq(id: faq.id, title: title, youtubeURL: url)
            }
        }
        .sheet(item: $addingEntryTo) { faq in
            FaqEntryEditSheet(question: "", answer: "", isNew: true) { question, answer in
                store.addFaqEntry(faqID: faq.id, question: question, answer: answer)
            }
        }
        .sheet(item: $editingEntry) { entry in
            FaqEntryEditSheet(question: entry.question, answer: entry.answer, isNew: false) { question, answer in
                store.updateFaqEntry(id: entry.id, question: question, answer: answer)
            }
        }
        .confirmationDialog("Delete this FAQ and its questions?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let faq = confirmingDelete {
                    store.deleteFaq(faq.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
        .confirmationDialog("Delete this question?", isPresented: Binding(
            get: { confirmingDeleteEntry != nil },
            set: { if !$0 { confirmingDeleteEntry = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let entry = confirmingDeleteEntry {
                    store.deleteFaqEntry(entry.id)
                }
                confirmingDeleteEntry = nil
            }
            Button("Cancel", role: .cancel) { confirmingDeleteEntry = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FAQ")
                    .font(.title.bold())
                Text("\(store.faqEntries.count) questions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add FAQ", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        TextField("Search", text: $searchText)
            .textFieldStyle(.roundedBorder)
            .frame(width: 160)
    }
}

// MARK: - FAQ card

struct FaqCard: View {
    @EnvironmentObject var store: Store
    let faq: Faq
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onAddEntry: () -> Void
    let onEditEntry: (FaqEntry) -> Void
    let onDeleteEntry: (FaqEntry) -> Void

    private var entries: [FaqEntry] {
        store.faqEntries(for: faq.id)
    }

    private var youtubeID: String? {
        youtubeVideoID(from: faq.youtubeURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if let id = youtubeID {
                    YouTubeThumb(videoID: id)
                        .frame(width: 88, height: 50)
                        .cornerRadius(6)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(faq.title)
                        .font(.headline)
                    Text("\(entries.count) question\(entries.count == 1 ? "" : "s")" + (youtubeID != nil ? " · YouTube" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    onToggleExpand()
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                Menu {
                    if let id = youtubeID {
                        Button("Open on YouTube") {
                            if let url = URL(string: "https://www.youtube.com/watch?v=\(id)") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    }
                    Button("Edit", action: onEdit)
                    Button("Move Up", action: onMoveUp)
                    Button("Move Down", action: onMoveDown)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }

            if isExpanded {
                Divider()

                if entries.isEmpty {
                    Text("No questions yet. Add one manually or paste a full FAQ on the next one you add.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    VStack(spacing: 8) {
                        ForEach(entries) { entry in
                            FaqEntryRow(
                                entry: entry,
                                onEdit: { onEditEntry(entry) },
                                onDelete: { onDeleteEntry(entry) },
                                onMoveUp: { store.moveFaqEntry(id: entry.id, faqID: faq.id, direction: -1) },
                                onMoveDown: { store.moveFaqEntry(id: entry.id, faqID: faq.id, direction: 1) }
                            )
                        }
                    }
                }

                Button {
                    onAddEntry()
                } label: {
                    Label("Add Question", systemImage: "plus.circle")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .card()
    }
}

// MARK: - Entry row

struct FaqEntryRow: View {
    let entry: FaqEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private var renderedAnswer: AttributedString? {
        let trimmed = entry.answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(entry.question)
                    .font(.callout.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Move Up", action: onMoveUp)
                    Button("Move Down", action: onMoveDown)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .menuStyle(.borderlessButton)
            }
            if let answer = renderedAnswer {
                Text(answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.primary.opacity(0.04))
        )
    }
}

// MARK: - Edit sheets

struct FaqEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String, String) -> Void

    @State private var title: String
    @State private var youtubeURL: String
    @State private var pasted: String

    init(title: String = "", youtubeURL: String = "", onSave: @escaping (String, String, String) -> Void) {
        self.onSave = onSave
        _title = State(initialValue: title)
        _youtubeURL = State(initialValue: youtubeURL)
        _pasted = State(initialValue: "")
    }

    private var isEditing: Bool {
        !title.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isEditing ? "Edit FAQ" : "New FAQ")
                .font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            TextField("Video link (YouTube…)", text: $youtubeURL)
                .textFieldStyle(.roundedBorder)
            if !isEditing {
                Text("Paste the FAQ ChatGPT wrote from the transcript below. Lines starting with Q1. / Q2. … become questions — everything after is that question's answer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $pasted)
                    .frame(height: 160)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3))
                    )
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(title, youtubeURL, pasted)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420)
    }
}

struct FaqEntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let isNew: Bool
    let onSave: (String, String) -> Void

    @State private var question: String
    @State private var answer: String

    init(question: String, answer: String, isNew: Bool, onSave: @escaping (String, String) -> Void) {
        self.isNew = isNew
        self.onSave = onSave
        _question = State(initialValue: question)
        _answer = State(initialValue: answer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isNew ? "New Question" : "Edit Question")
                .font(.headline)
            TextField("Question", text: $question)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $answer)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
            Text("Answer — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(question, answer)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 420)
    }
}