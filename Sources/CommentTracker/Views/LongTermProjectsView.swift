import SwiftUI
import AppKit

struct LongTermProjectsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""
    @State private var editing: LongTermProject?
    @State private var confirmingDelete: LongTermProject?
    @State private var expandedID: Int?

    private var projects: [LongTermProject] {
        var list = store.longTermProjects
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.longTermProject($0, matches: q) }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if projects.isEmpty {
                        Text("No long-term projects yet. Add one — the things you keep coming back to for months.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(projects) { project in
                        LongTermProjectCard(
                            project: project,
                            isExpanded: expandedID == project.id,
                            onToggleExpand: {
                                expandedID = expandedID == project.id ? nil : project.id
                            },
                            onEdit: { editing = project },
                            onDelete: { confirmingDelete = project },
                            onMoveUp: { store.moveLongTermProject(id: project.id, direction: -1) },
                            onMoveDown: { store.moveLongTermProject(id: project.id, direction: 1) }
                        )
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingAdd) {
            LongTermProjectEditSheet { title, description, nextAction, status, started, target in
                store.addLongTermProject(title: title, description: description, nextAction: nextAction, status: status, startedAt: started, targetAt: target)
            }
        }
        .sheet(item: $editing) { project in
            LongTermProjectEditSheet(
                title: project.title,
                description: project.description,
                nextAction: project.nextAction,
                status: project.status,
                progress: project.progress,
                startedAt: project.startedAt,
                targetAt: project.targetAt
            ) { title, description, nextAction, status, started, target in
                store.updateLongTermProject(id: project.id, title: title, description: description, nextAction: nextAction, status: status, progress: project.progress, startedAt: started, targetAt: target)
            }
        }
        .confirmationDialog("Delete this project and its milestones?", isPresented: Binding(
            get: { confirmingDelete != nil },
            set: { if !$0 { confirmingDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let project = confirmingDelete {
                    store.deleteLongTermProject(project.id)
                }
                confirmingDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmingDelete = nil }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Long Term Projects")
                    .font(.title.bold())
                Text("\(store.longTermProjects.filter { $0.status == .active }.count) active")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("Add Project", systemImage: "plus")
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

// MARK: - Card

struct LongTermProjectCard: View {
    @EnvironmentObject var store: Store
    let project: LongTermProject
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void

    private var milestones: [LongTermMilestone] {
        store.milestones(for: project.id)
    }

    private var doneMilestones: Int {
        milestones.filter { $0.done }.count
    }

    private var renderedDescription: AttributedString? {
        let trimmed = project.description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? AttributedString(markdown: trimmed, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
    }

    private var dateSummary: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        var parts: [String] = []
        if let start = project.startedAt {
            parts.append("Started \(formatter.string(from: start))")
        }
        if let target = project.targetAt {
            parts.append("Target \(formatter.string(from: target))")
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Button {
                    onToggleExpand()
                } label: {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title)
                        .font(.headline)
                    if !project.nextAction.isEmpty {
                        Text("Next: \(project.nextAction)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(project.status.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(project.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(project.status.color.opacity(0.12), in: Capsule())
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Move Up", action: onMoveUp)
                    Button("Move Down", action: onMoveDown)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }

            HStack(spacing: 8) {
                Text("\(project.progress)%")
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 38, alignment: .leading)
                ProgressView(value: Double(project.progress), total: 100)
                    .tint(project.status.color)
                if !milestones.isEmpty {
                    Text("\(doneMilestones)/\(milestones.count) milestones")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            if isExpanded {
                Divider()

                if let rendered = renderedDescription {
                    Text(rendered)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .environment(\.openURL, OpenURLAction { url in
                            NSWorkspace.shared.open(url)
                            return .handled
                        })
                }

                HStack(spacing: 6) {
                    Slider(value: progressBinding, in: 0...100, step: 5)
                    Text("\(project.progress)%")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if !dateSummary.isEmpty {
                    Text(dateSummary)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Milestones")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    if milestones.isEmpty {
                        Text("No milestones yet.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        VStack(spacing: 4) {
                            ForEach(milestones) { milestone in
                                milestoneRow(milestone)
                            }
                        }
                    }
                    addMilestoneField
                }
            }
        }
        .card()
    }

    private var progressBinding: Binding<Double> {
        Binding(
            get: { Double(project.progress) },
            set: { store.setLongTermProjectProgress(id: project.id, progress: Int($0)) }
        )
    }

    private func milestoneRow(_ milestone: LongTermMilestone) -> some View {
        HStack(spacing: 8) {
            Button {
                store.toggleLongTermMilestone(id: milestone.id)
            } label: {
                Image(systemName: milestone.done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(milestone.done ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            Text(milestone.title)
                .font(.subheadline)
                .strikethrough(milestone.done, color: .secondary)
                .foregroundStyle(milestone.done ? .secondary : .primary)
            Spacer()
            Button {
                store.moveLongTermMilestone(id: milestone.id, projectID: project.id, direction: -1)
            } label: {
                Image(systemName: "chevron.up")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            Button {
                store.moveLongTermMilestone(id: milestone.id, projectID: project.id, direction: 1)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
            Button {
                store.deleteLongTermMilestone(milestone.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(6)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
    }

    @State private var milestoneText = ""

    private var addMilestoneField: some View {
        HStack(spacing: 8) {
            TextField("Add a milestone…", text: $milestoneText)
                .textFieldStyle(.roundedBorder)
                .onSubmit(addMilestone)
            Button {
                addMilestone()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.borderless)
            .disabled(milestoneText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private func addMilestone() {
        let trimmed = milestoneText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addLongTermMilestone(projectID: project.id, title: trimmed)
        milestoneText = ""
    }
}

// MARK: - Edit sheet

struct LongTermProjectEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (String, String, String, LongTermProjectStatus, Date?, Date?) -> Void

    @State private var title: String
    @State private var description: String
    @State private var nextAction: String
    @State private var status: LongTermProjectStatus
    @State private var progress: Int
    @State private var startedAt: Date?
    @State private var targetAt: Date?
    @State private var hasStarted: Bool
    @State private var hasTarget: Bool

    init(
        title: String = "",
        description: String = "",
        nextAction: String = "",
        status: LongTermProjectStatus = .active,
        progress: Int = 0,
        startedAt: Date? = nil,
        targetAt: Date? = nil,
        onSave: @escaping (String, String, String, LongTermProjectStatus, Date?, Date?) -> Void
    ) {
        self.onSave = onSave
        _title = State(initialValue: title)
        _description = State(initialValue: description)
        _nextAction = State(initialValue: nextAction)
        _status = State(initialValue: status)
        _progress = State(initialValue: progress)
        _startedAt = State(initialValue: startedAt)
        _targetAt = State(initialValue: targetAt)
        _hasStarted = State(initialValue: startedAt != nil)
        _hasTarget = State(initialValue: targetAt != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.isEmpty ? "New Long Term Project" : "Edit Project")
                .font(.headline)
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
            Picker("Status", selection: $status) {
                ForEach(LongTermProjectStatus.allCases) { s in
                    Text(s.label).tag(s)
                }
            }
            .pickerStyle(.segmented)
            TextField("Next action", text: $nextAction)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $description)
                .frame(height: 90)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3))
                )
            Text("Description — markdown supported")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Toggle("Started", isOn: $hasStarted)
                if hasStarted {
                    DatePicker("", selection: startDateBinding, displayedComponents: .date)
                }
            }
            HStack(spacing: 16) {
                Toggle("Target", isOn: $hasTarget)
                if hasTarget {
                    DatePicker("", selection: targetDateBinding, displayedComponents: .date)
                }
            }

            HStack {
                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: progressBinding, in: 0...100, step: 5)
                Text("\(progress)%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    onSave(title, description, nextAction, status, hasStarted ? startedAt ?? Date() : nil, hasTarget ? targetAt ?? Date() : nil)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 440)
    }

    private var startDateBinding: Binding<Date> {
        Binding(
            get: { startedAt ?? Date() },
            set: { startedAt = $0 }
        )
    }

    private var targetDateBinding: Binding<Date> {
        Binding(
            get: { targetAt ?? Date() },
            set: { targetAt = $0 }
        )
    }

    private var progressBinding: Binding<Double> {
        Binding(
            get: { Double(progress) },
            set: { progress = Int($0) }
        )
    }
}
