import SwiftUI
import AppKit

struct ProjectTrackerView: View {
    @EnvironmentObject var store: Store
    @State private var newName = ""
    @State private var editing: Project?

    private var working: Project? { store.projects.first { $0.status == .working } }
    private var inProgress: [Project] { store.projects.filter { $0.status == .inProgress } }
    private var completed: [Project] { store.projects.filter { $0.status == .completed } }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VStack(spacing: 10) {
                addBar
            }
            .padding(16)
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let project = working {
                        workingSection(project)
                    }
                    if !inProgress.isEmpty {
                        statusSection("In Progress", projects: inProgress, accent: .blue)
                    }
                    if !completed.isEmpty {
                        statusSection("Completed", projects: completed, accent: .gray)
                    }
                    if working == nil && inProgress.isEmpty && completed.isEmpty {
                        emptyState
                    }
                }
                .padding([.horizontal, .bottom], 16)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(item: $editing) { project in
            ProjectEditSheet(project: project)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Projects")
                    .font(.title.bold())
                Text("\(inProgress.count) in progress · \(completed.count) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Text("One Working project at a time")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    private var addBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.green)
            TextField("Add a project…", text: $newName)
                .textFieldStyle(.plain)
                .onSubmit(add)
            Button(action: add) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.15), lineWidth: 1))
    }

    private func workingSection(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.green)
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENTLY WORKING")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.green)
                    Text(project.name)
                        .font(.title3.bold())
                }
                Spacer()
                Button {
                    store.stopProject(project.id)
                } label: {
                    Label("Stop", systemImage: "stop.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .help("Move back to In Progress")
            }
            notesLine(project.startNote, label: "How to start")
            notesLine(project.stopNote, label: "How to stop")
            HStack {
                Spacer()
                Button("Edit") { editing = project }
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color.green.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1.5))
    }

    private func statusSection(_ title: String, projects projects: [Project], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 8) {
                ForEach(projects) { project in
                    ProjectCardView(project: project) {
                        editing = project
                    }
                }
            }
        }
    }

    private func notesLine(_ text: String, label: String) -> some View {
        Group {
            if !text.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text("\(label):")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "shippingbox")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No projects yet — add one above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func add() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.addProject(name: trimmed)
        newName = ""
    }
}

// MARK: - Project card

struct ProjectCardView: View {
    @EnvironmentObject var store: Store
    let project: Project
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: project.status.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(project.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.subheadline.weight(.semibold))
                if project.status == .completed {
                    Text(project.status.displayName)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
            if project.status == .inProgress {
                Button {
                    store.startProject(project.id)
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .help("Start working on this now")
            } else if project.status == .completed {
                Button {
                    store.setProjectStatus(project.id, .inProgress)
                } label: {
                    Label("Reopen", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.bordered)
            }
            Menu {
                if project.status != .completed {
                    Button { store.setProjectStatus(project.id, .completed) } label: { Label("Mark completed", systemImage: "checkmark.circle") }
                }
                Button { onEdit?() } label: { Label("Edit start/stop notes", systemImage: "pencil") }
                Divider()
                Button(role: .destructive) { store.deleteProject(project.id) } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.14), lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Edit sheet

struct ProjectEditSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: Store
    let project: Project
    @State private var startNote: String
    @State private var stopNote: String

    init(project: Project) {
        self.project = project
        _startNote = State(initialValue: project.startNote)
        _stopNote = State(initialValue: project.stopNote)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(project.name)
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text("How to start")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $startNote)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    .frame(height: 80)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("How to stop")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextEditor(text: $stopNote)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                    .frame(height: 80)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    store.updateProjectNotes(project.id, startNote: startNote, stopNote: stopNote)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(width: 460, height: 360)
    }
}