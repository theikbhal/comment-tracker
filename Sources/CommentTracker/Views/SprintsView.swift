import SwiftUI
import AppKit

struct SprintsView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""

    private var sprints: [Sprint] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.sprints
            .filter { store.sprint($0, matches: searchText) || (!q.isEmpty && self.containsMatch($0)) }
            .sorted {
                if $0.done != $1.done { return !$0.done }
                return $0.updatedAt > $1.updatedAt
            }
    }

    private func containsMatch(_ s: Sprint) -> Bool {
        store.stories.filter { $0.sprintId == s.id }.contains { store.story($0, matches: searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if store.sprints.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(sprints) { sprint in
                            SprintCardView(sprint: sprint)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            SprintFormView()
                .environmentObject(store)
        }
        .sheet(item: $store.sprintToDetail) { sprint in
            SprintDetailView(sprintID: sprint.id)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Sprints")
                    .font(.title.bold())
                let open = store.sprints.filter { !$0.done }.count
                Text("\(open) open of \(store.sprints.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                showingAdd = true
            } label: {
                Label("New Sprint", systemImage: "flag")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search sprints, stories…", text: $searchText)
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No sprints yet — create your first")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Sprint Card

struct SprintCardView: View {
    @EnvironmentObject var store: Store
    let sprint: Sprint

    private var stories: [Story] { store.storiesForSprint(sprint.id) }
    private var tasks: [StoryTask] { store.tasksForSprint(sprint.id) }
    private var doneCount: Int { tasks.filter(\.done).count }
    private var progress: Double { tasks.isEmpty ? 0 : Double(doneCount) / Double(tasks.count) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: sprint.done ? "flag.checkered" : "flag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background((sprint.done ? Color.green : Color.orange).gradient, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text(sprint.name)
                        .font(.headline)
                        .strikethrough(sprint.done)
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .foregroundStyle(.tertiary)
                        Text(sprintRange)
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .monospacedDigit()
                }
                Spacer()
                Text("\(doneCount)/\(tasks.count) tasks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: progress)
                .tint(sprint.done ? .green : .orange)
            HStack {
                Text("\(stories.count) stories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !sprint.notes.isEmpty {
                    Text("· \(sprint.notes)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Spacer()
                Text(sprint.updatedAt.formatted(date: .numeric, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(sprint.done ? Color.green.opacity(0.4) : Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            store.sprintToDetail = sprint
        }
        .contextMenu {
            Button {
                store.sprintToDetail = sprint
            } label: {
                Label("Open", systemImage: "arrow.up.right.square")
            }
            Button {
                store.updateSprint(id: sprint.id, done: !sprint.done)
            } label: {
                Label(sprint.done ? "Reopen" : "Mark done", systemImage: sprint.done ? "arrow.counterclockwise" : "checkmark")
            }
            Divider()
            Button(role: .destructive) {
                store.deleteSprint(sprint.id)
            } label: {
                Label("Delete sprint", systemImage: "trash")
            }
        }
    }

    private var sprintRange: String {
        guard let start = sprint.startAt else {
            if let end = sprint.endAt {
                return "Ends " + end.formatted(date: .abbreviated, time: .shortened)
            }
            return "Not scheduled"
        }
        if let end = sprint.endAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d · HH:mm"
            return "\(formatter.string(from: start)) — \(formatter.string(from: end))"
        }
        return start.formatted(date: .abbreviated, time: .shortened) + " →"
    }
}

// MARK: - Create / Edit form

struct SprintFormView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    var existing: Sprint? = nil

    @State private var name = ""
    @State private var notes = ""
    @State private var showSchedule = false
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(3600)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(existing == nil ? "New Sprint" : "Edit Sprint")
                .font(.title2.bold())
            TextField("Sprint name", text: $name)
                .textFieldStyle(.roundedBorder)

            TextField("Notes (optional)", text: $notes)
                .textFieldStyle(.roundedBorder)

            Toggle("Schedule start / end", isOn: $showSchedule)
                .toggleStyle(.checkbox)
            if showSchedule {
                HStack(spacing: 10) {
                    DatePicker("Start", selection: $start)
                    DatePicker("End", selection: $end)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Duration presets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        ForEach(SprintPreset.allCases) { preset in
                            Button(preset.label) {
                                end = start.addingTimeInterval(TimeInterval(preset.rawValue) * 60)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            if let existing {
                HStack {
                    Spacer()
                    Button("Delete sprint") {
                        store.deleteSprint(existing.id)
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.red)
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    let startAt = showSchedule ? start : nil
                    let endAt = showSchedule ? end : nil
                    if let existing {
                        store.updateSprint(id: existing.id, name: name, startAt: startAt, endAt: endAt, notes: notes)
                    } else {
                        store.addSprint(name: name, startAt: startAt, endAt: endAt, notes: notes)
                    }
                    dismiss()
                } label: {
                    Label(existing == nil ? "Create" : "Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
        .onAppear {
            if let existing {
                name = existing.name
                notes = existing.notes
                if let s = existing.startAt {
                    showSchedule = true
                    start = s
                    end = existing.endAt ?? s.addingTimeInterval(3600)
                }
            }
        }
    }
}

// MARK: - Sprint detail

struct SprintDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let sprintID: Int
    @State private var editing = false
    @State private var newStory = ""

    private var sprint: Sprint? { store.sprints.first { $0.id == sprintID } }
    private var stories: [Story] { store.storiesForSprint(sprintID) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let sprint {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sprint.name)
                            .font(.title2.bold())
                            .strikethrough(sprint.done)
                        Text(sprintRange(sprint))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Spacer()
                    Button {
                        store.updateSprint(id: sprint.id, done: !sprint.done)
                    } label: {
                        Label(sprint.done ? "Reopen" : "Mark done", systemImage: sprint.done ? "arrow.counterclockwise" : "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(sprint.done ? .gray : .green)
                    .help("Marking done adds a Win")
                    Button {
                        editing = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .help("Close")
                    .keyboardShortcut(.cancelAction)
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Add a story…", text: $newStory)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        store.addStory(sprintId: sprint.id, title: newStory)
                        newStory = ""
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newStory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.return, modifiers: .command)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        if stories.isEmpty {
                            Text("No stories yet. A story is a capability you build — break it into tasks.")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 24)
                        }
                        ForEach(stories) { story in
                            StoryBlockView(story: story)
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 560, height: 520)
        .sheet(isPresented: $editing) {
            if let sprint {
                SprintFormView(existing: sprint)
                    .environmentObject(store)
            }
        }
    }

    private func sprintRange(_ s: Sprint) -> String {
        switch (s.startAt, s.endAt) {
        case (let st?, let en?):
            return st.formatted(date: .abbreviated, time: .shortened) + " — " + en.formatted(date: .abbreviated, time: .shortened)
        case (let st?, nil):
            return "Starts " + st.formatted(date: .abbreviated, time: .shortened)
        case (nil, _):
            return "Not scheduled"
        }
    }
}

// MARK: - Story block

struct StoryBlockView: View {
    @EnvironmentObject var store: Store
    @State private var editing = false
    @State private var newTask = ""
    let story: Story

    private var tasks: [StoryTask] { store.tasksForStory(story.id) }
    private var doneCount: Int { tasks.filter(\.done).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(story.title)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(doneCount)/\(tasks.count)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Button { editing = true } label: { Image(systemName: "pencil").font(.caption) }
                    .buttonStyle(.plain)
                    .help("Edit story")
                Button { store.deleteStory(story.id) } label: { Image(systemName: "trash").font(.caption) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                    .help("Delete story")
            }
            HStack(spacing: 8) {
                TextField("Add a task…", text: $newTask)
                    .textFieldStyle(.plain)
                    .padding(6)
                    .background(.background.secondary, in: RoundedRectangle(cornerRadius: 6))
                Button {
                    store.addTask(storyId: story.id, title: newTask)
                    newTask = ""
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.bordered)
                .disabled(newTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            ForEach(tasks) { task in
                TaskRowView(task: task)
            }
        }
        .padding(10)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .sheet(isPresented: $editing) {
            EditStoryView(story: story)
                .environmentObject(store)
        }
    }
}

// MARK: - Task row

struct TaskRowView: View {
    @EnvironmentObject var store: Store
    @State private var editing = false
    let task: StoryTask

    var body: some View {
        HStack(spacing: 8) {
            Button {
                store.updateTask(id: task.id, done: !task.done)
            } label: {
                Image(systemName: task.done ? "checkmark.square.fill" : "square")
                    .foregroundStyle(task.done ? Color.green : .secondary)
            }
            .buttonStyle(.plain)
            .help("Marking done adds a win")
            Text(task.title)
                .font(.callout)
                .strikethrough(task.done)
                .foregroundStyle(task.done ? .secondary : .primary)
            Spacer()
            Button { editing = true } label: { Image(systemName: "pencil").font(.caption) }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Button { store.deleteTask(task.id) } label: { Image(systemName: "trash").font(.caption) }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
        }
        .padding(.horizontal, 6)
        .sheet(isPresented: $editing) {
            EditTaskView(task: task)
                .environmentObject(store)
        }
    }
}

// MARK: - Edit story (incl. move to another sprint)

struct EditStoryView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let story: Story
    @State private var title = ""
    @State private var targetSprintID: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Story")
                .font(.title2.bold())
            TextField("Story title", text: $title)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 6) {
                Text("Sprint")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Sprint", selection: $targetSprintID) {
                    Text("— keep current —").tag(Optional<Int>.none)
                    ForEach(store.sprints) { s in
                        Text(s.name).tag(Optional(s.id))
                    }
                }
                .labelsHidden()
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    store.updateStory(id: story.id, title: title, sprintId: targetSprintID ?? story.sprintId)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 380)
        .onAppear {
            title = story.title
            targetSprintID = nil
        }
    }
}

// MARK: - Edit task

struct EditTaskView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    let task: StoryTask
    @State private var title = ""
    @State private var done = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Task")
                .font(.title2.bold())
            TextField("Task", text: $title)
                .textFieldStyle(.roundedBorder)
            Toggle("Done", isOn: $done)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    store.updateTask(id: task.id, title: title, done: done)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 360)
        .onAppear {
            title = task.title
            done = task.done
        }
    }
}