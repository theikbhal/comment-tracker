import SwiftUI
import AppKit

struct ChallengeView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: Challenge?

    private var totalCount: Int { store.challenges.count }
    private var activeCount: Int { store.challenges(for: .active).count }

    private func cards(for status: ChallengeStatus) -> [Challenge] {
        store.challenges(for: status).filter { store.challenge($0, matches: searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(ChallengeStatus.allCases) { status in
                        challengeColumn(status)
                    }
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAdd) {
            ChallengeEditSheet { title, body, startDate, endDate in
                store.addChallenge(title: title, body: body, status: .active, startDate: startDate, endDate: endDate)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { challenge in
            ChallengeEditSheet(
                existing: challenge,
                onSave: { title, body, startDate, endDate in
                    store.updateChallenge(id: challenge.id, title: title, body: body, startDate: startDate, endDate: endDate)
                }
            )
            .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Challenges")
                    .font(.title.bold())
                Text("\(activeCount) active · \(totalCount) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Challenge", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search challenges…", text: $searchText)
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

    private func challengeColumn(_ status: ChallengeStatus) -> some View {
        let items = cards(for: status)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: status.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(status.color)
                Text(status.displayName)
                    .font(.headline)
                Spacer()
                Text("\(items.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(items) { challenge in
                        ChallengeCardView(challenge: challenge) {
                            editing = challenge
                        }
                    }
                    if items.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: status.symbol)
                                .font(.system(size: 22))
                                .foregroundStyle(.tertiary)
                            Text("No challenges here")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 280)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 14).fill(status.color.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
    }
}

// MARK: - Card

struct ChallengeCardView: View {
    @EnvironmentObject var store: Store
    let challenge: Challenge
    let onOpenFull: () -> Void

    private var renderedBody: AttributedString? {
        let trimmed = challenge.body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: challenge.status.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(challenge.status.color.gradient, in: RoundedRectangle(cornerRadius: 6))
                Text(challenge.title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
                statusMenu
            }
            if let rendered = renderedBody {
                Text(rendered)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .environment(\.openURL, OpenURLAction { url in
                        NSWorkspace.shared.open(url)
                        return .handled
                    })
            }
            if !challenge.dateRangeText.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.system(size: 10))
                    Text(challenge.dateRangeText)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(challenge.status.color)
                .frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture { onOpenFull() }
        .contextMenu {
            Button { onOpenFull() } label: {
                Label("Edit challenge…", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                store.deleteChallenge(challenge.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(ChallengeStatus.allCases) { s in
                Button {
                    store.setChallengeStatus(id: challenge.id, status: s)
                } label: {
                    if s == challenge.status {
                        Label(s.displayName, systemImage: "checkmark")
                    } else {
                        Text(s.displayName)
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right.circle")
                .font(.system(size: 13))
                .foregroundStyle(challenge.status.color)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Move to another status")
    }
}

// MARK: - Edit sheet

struct ChallengeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: Challenge? = nil
    let onSave: (String, String, String, String) -> Void

    @State private var title = ""
    @State private var note = ""
    @State private var startDate = ""
    @State private var endDate = ""

    private var renderedBody: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Challenge" : "Edit Challenge")
                .font(.title2.bold())
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 10) {
                TextField("Start date (e.g. Aug 7)", text: $startDate)
                    .textFieldStyle(.roundedBorder)
                TextField("End date (e.g. Sep 7)", text: $endDate)
                    .textFieldStyle(.roundedBorder)
            }
            Text("Note — markdown supported ([link](https://…), **bold**, lists)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 150)
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
            if let rendered = renderedBody, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                    onSave(title, note, startDate, endDate)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            if let existing {
                title = existing.title
                note = existing.body
                startDate = existing.startDate
                endDate = existing.endDate
            }
        }
    }
}
