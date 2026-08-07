import SwiftUI
import AppKit

struct FamilyView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: FamilyMember?
    @State private var confirmingDelete: FamilyMember?

    private var members: [FamilyMember] {
        var list = store.sortedFamilyMembers
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.familyMember($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if members.isEmpty {
                        Text("No family yet — add the people who matter.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                        FamilyRow(member: member, isFirst: index == 0, isLast: index == members.count - 1) {
                            editing = member
                        } onDelete: {
                            confirmingDelete = member
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 720, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            FamilyEditSheet { name, relation, birthday, note in
                store.addFamilyMember(name: name, relation: relation, birthday: birthday, note: note)
            }
            .environmentObject(store)
        }
        .sheet(item: $editing) { member in
            FamilyEditSheet(
                existing: member,
                onSave: { name, relation, birthday, note in
                    store.updateFamilyMember(id: member.id, name: name, relation: relation, birthday: birthday, note: note)
                }
            )
            .environmentObject(store)
        }
        .confirmationDialog("Remove this family member?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if let member = confirmingDelete {
                    store.deleteFamilyMember(member.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        } message: {
            Text(confirmingDelete.map { "This removes \"\($0.name)\" and their note." } ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Family")
                    .font(.title.bold())
                Text("\(store.familyMembers.count) member\(store.familyMembers.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Member", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search family…", text: $searchText)
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
}

// MARK: - Row

struct FamilyRow: View {
    @EnvironmentObject var store: Store
    let member: FamilyMember
    let isFirst: Bool
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var renderedNote: AttributedString? {
        let trimmed = member.note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Button {
                    store.moveFamilyMember(id: member.id, direction: -1)
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isFirst)
                .opacity(isFirst ? 0.3 : 1)
                .help("Move up")
                Button {
                    store.moveFamilyMember(id: member.id, direction: 1)
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                }
                .buttonStyle(.plain)
                .disabled(isLast)
                .opacity(isLast ? 0.3 : 1)
                .help("Move down")
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Color.green.gradient)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name)
                            .font(.subheadline.weight(.bold))
                        if !member.relation.isEmpty {
                            Text(member.relation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    if member.hasBirthday {
                        HStack(spacing: 4) {
                            Image(systemName: "birthday.cake.fill")
                                .font(.system(size: 10))
                            Text(birthdayChipText)
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(birthdayColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(birthdayColor.opacity(0.12), in: Capsule())
                        .help("\(member.birthdayText) birthday")
                    }
                    Button {
                        onEdit()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .help("Edit member")
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.borderless)
                    .help("Remove member")
                }
                if let rendered = renderedNote {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .onTapGesture(count: 2) { onEdit() }
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit member…", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var birthdayChipText: String {
        guard let days = member.daysUntilBirthday else { return member.birthdayText }
        if days == 0 { return "Today!" }
        if days == 1 { return "Tomorrow" }
        return "\(member.birthdayText) · \(days)d"
    }

    private var birthdayColor: Color {
        guard let days = member.daysUntilBirthday, days <= 7 else { return .secondary }
        return days == 0 ? .pink : .orange
    }
}

// MARK: - Edit sheet

struct FamilyEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    var existing: FamilyMember? = nil
    let onSave: (String, String, String, String) -> Void

    @State private var name = ""
    @State private var relation = ""
    @State private var note = ""
    @State private var hasBirthday = false
    @State private var birthday = Date()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private var renderedNote: AttributedString? {
        try? AttributedString(markdown: note, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(existing == nil ? "Add Family Member" : "Edit Family Member")
                .font(.title2.bold())
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Relation (e.g. Mom, Brother)", text: $relation)
                .textFieldStyle(.roundedBorder)
            HStack(spacing: 10) {
                Toggle(isOn: $hasBirthday) {
                    Label("Birthday", systemImage: "birthday.cake")
                        .font(.caption)
                        .fixedSize()
                }
                .toggleStyle(.checkbox)
                if hasBirthday {
                    DatePicker("", selection: $birthday, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                }
            }
            Text("Note — markdown supported ([link](https://…), **bold**)")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: $note)
                .font(.body.monospaced())
                .frame(height: 100)
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
                    let bd = hasBirthday ? Self.dayFormatter.string(from: birthday) : ""
                    onSave(name, relation, bd, note)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            if let existing {
                name = existing.name
                relation = existing.relation
                note = existing.note
                if existing.hasBirthday, let d = dateFromDay(existing.birthday) {
                    hasBirthday = true
                    birthday = d
                }
            }
        }
    }
}
