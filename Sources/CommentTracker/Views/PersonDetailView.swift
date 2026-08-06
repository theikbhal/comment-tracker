import SwiftUI
import AppKit

struct PersonDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let personID: Int

    @State private var name = ""
    @State private var brief = ""
    @State private var descriptionText = ""
    @State private var newComment = ""
    @State private var newLinkLabel = ""
    @State private var newLinkURL = ""
    @State private var newLinkKind: PersonLinkKind = .x

    private var person: Person? { store.personByID(personID) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    fieldsSection
                    linksSection
                    commentsSection
                }
                .padding(20)
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 620)
        .onAppear(perform: loadFields)
        .onChange(of: store.people) {
            loadFields()
        }
    }

    private func loadFields() {
        guard let p = person else { return }
        name = p.name
        brief = p.brief
        descriptionText = p.description
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.blue.gradient)
            VStack(alignment: .leading, spacing: 2) {
                TextField("Name", text: $name)
                    .font(.title2.bold())
                    .textFieldStyle(.plain)
                    .onSubmit { saveFields() }
                Text("Updated \(person?.updatedAt.formatted(date: .abbreviated, time: .shortened) ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let p = person {
                Picker("List", selection: Binding(
                    get: { p.stage },
                    set: { store.updatePerson(id: personID, stage: $0) }
                )) {
                    ForEach(PersonStage.allCases) { s in
                        Text("\(s.displayName)").tag(s)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
            }
        }
        .padding(16)
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Brief", systemImage: "text.alignleft")
                    .font(.headline)
                TextField("One line — who they are", text: $brief)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { saveFields() }
            }
            VStack(alignment: .leading, spacing: 4) {
                Label("Description", systemImage: "doc.text")
                    .font(.headline)
                TextEditor(text: $descriptionText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(minHeight: 90)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
                HStack {
                    Text("Save edits automatically")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Button("Save") { saveFields() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func saveFields() {
        store.updatePerson(id: personID, name: name, brief: brief, description: descriptionText)
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Links", systemImage: "link")
                .font(.headline)

            if store.links(for: personID).isEmpty {
                Text("No links yet. Add their X, YouTube, Instagram, video or website.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.links(for: personID).enumerated()), id: \.element.id) { index, link in
                        linkRow(link)
                        if index < store.links(for: personID).count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            }

            addLinkRow
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func linkRow(_ link: PersonLink) -> some View {
        HStack(spacing: 10) {
            Image(systemName: link.kind.symbol)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 0) {
                Text(link.label.isEmpty ? link.kind.displayName : link.label)
                    .font(.subheadline.weight(.medium))
                Text(link.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            if let url = URL(string: link.url) {
                Button {
                    NSWorkspace.shared.open(url)
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
                .help("Open \(link.url)")
            }
            Button {
                store.deletePersonLink(link.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help("Remove link")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var addLinkRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Picker("Kind", selection: $newLinkKind) {
                    ForEach(PersonLinkKind.allCases) { kind in
                        Label(kind.displayName, systemImage: kind.symbol).tag(kind)
                    }
                }
                .labelsHidden()
                .frame(width: 130)
                TextField("Label", text: $newLinkLabel)
                    .textFieldStyle(.roundedBorder)
                TextField("https://…", text: $newLinkURL)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Enter a full URL — x.com, youtube, instagram, any link")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    store.addPersonLink(personID: personID, label: newLinkLabel, url: newLinkURL, kind: newLinkKind)
                    newLinkLabel = ""
                    newLinkURL = ""
                } label: {
                    Label("Add Link", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(newLinkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    // MARK: - Comments

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Comments", systemImage: "bubble.left.and.bubble.right")
                .font(.headline)

            if store.comments(for: personID).isEmpty {
                Text("Nothing yet — leave a note like Trello.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(store.comments(for: personID).enumerated()), id: \.element.id) { index, comment in
                        commentRow(comment)
                        if index < store.comments(for: personID).count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            }

            HStack(alignment: .bottom, spacing: 8) {
                TextEditor(text: $newComment)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .frame(height: 56)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    )
                    .overlay(alignment: .topLeading) {
                        if newComment.isEmpty {
                            Text("Write a comment…")
                                .font(.body)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 9)
                                .allowsHitTesting(false)
                        }
                    }
                Button {
                    store.addPersonComment(personID: personID, body: newComment)
                    newComment = ""
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                }
                .buttonStyle(.borderless)
                .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(16)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }

    private func commentRow(_ comment: PersonComment) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.crop.circle")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(comment.body)
                    .font(.subheadline)
                Text(comment.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                store.deletePerson(personID)
                store.personToDetail = nil
                dismiss()
            } label: {
                Label("Delete Person", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .tint(.red)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}
