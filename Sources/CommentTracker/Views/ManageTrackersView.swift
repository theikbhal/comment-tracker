import SwiftUI

struct ManageTrackersView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss
    @State private var showingAdd = false

    private var categories: [String] {
        var seen: [String] = []
        for t in store.trackers.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            if !seen.contains(t.category) {
                seen.append(t.category)
            }
        }
        return seen
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(categories, id: \.self) { category in
                        section(category)
                    }
                }
                .padding(16)
            }
            Divider()
            footer
        }
        .frame(width: 560, height: 600)
        .sheet(isPresented: $showingAdd) {
            AddTrackerView()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Manage Trackers")
                    .font(.title2.bold())
                Text("Toggle routines on or off. Disabled ones stay hidden but keep their data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                store.reseedMissingPresets()
            } label: {
                Label("Restore presets", systemImage: "arrow.counterclockwise")
            }
        }
        .padding(16)
    }

    private func section(_ category: String) -> some View {
        let trackers = store.trackers
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
        return VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.headline)
            VStack(spacing: 0) {
                ForEach(Array(trackers.enumerated()), id: \.element.id) { index, tracker in
                    row(tracker)
                    if index < trackers.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(6)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func row(_ tracker: Tracker) -> some View {
        HStack(spacing: 10) {
            Image(systemName: tracker.icon)
                .foregroundStyle(tracker.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 0) {
                Text(tracker.name)
                    .font(.subheadline.weight(.medium))
                Text(tracker.isPreset ? "Preset" : "Custom")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { tracker.enabled },
                set: { store.updateTracker(id: tracker.id, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.small)
            Button {
                store.deleteTracker(tracker.id)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.red)
            .help("Delete tracker and all its history")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    private var footer: some View {
        HStack {
            Button {
                showingAdd = true
            } label: {
                Label("Add Custom Tracker", systemImage: "plus")
            }
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
}

// MARK: - Add Tracker

struct AddTrackerView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Custom"
    @State private var icon = "checkmark.circle"
    @State private var colorName = "blue"
    @State private var isCounter = false
    @State private var target = 100
    @State private var scheduleNote = ""
    @State private var newCategory = ""

    private let iconChoices = [
        "checkmark.circle", "sunrise", "sun.max", "sun.horizon", "sunset", "moon.stars",
        "book", "sparkles", "drop.fill", "hands.sparkles", "moon.fill", "building.columns",
        "heart", "ear", "house", "phone", "figure.2", "textformat", "clock", "heart.circle",
        "person.2", "laptopcomputer", "briefcase", "shoeprints.fill", "fork.knife", "hammer",
        "megaphone", "chart.line.uptrend", "gearshape.2", "star", "flame", "leaf", "dumbbell.fill",
        "pencil", "cart", "dollarsign.circle", "graduationcap", "calendar", "list.bullet",
    ]

    private var categoryChoices: [String] {
        var cats = store.trackers.map { $0.category }
        if !newCategory.isEmpty && !cats.contains(newCategory) {
            cats.append(newCategory)
        }
        if !cats.contains(category) {
            cats.append(category)
        }
        if !cats.contains("Custom") {
            cats.append("Custom")
        }
        return cats
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Custom Tracker")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. Read 20 pages", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Category", selection: $category) {
                        ForEach(categoryChoices, id: \.self) { Text($0) }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("New category (optional)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("or type a new one", text: $newCategory)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            let t = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !t.isEmpty { category = t }
                        }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Type")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Type", selection: $isCounter) {
                    Text("Checkbox (done / not done)").tag(false)
                    Text("Counter (count up to a target)").tag(true)
                }
                .pickerStyle(.segmented)
            }

            if isCounter {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Daily target")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Stepper(value: $target, in: 1...100000, step: 10) {
                            EmptyView()
                        }
                        Text("\(target)")
                            .font(.headline)
                            .monospacedDigit()
                            .frame(minWidth: 70, alignment: .trailing)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Schedule note (optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("e.g. Every Thursday", text: $scheduleNote)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 9), spacing: 6) {
                    ForEach(iconChoices, id: \.self) { choice in
                        Button {
                            icon = choice
                        } label: {
                            Image(systemName: choice)
                                .font(.system(size: 15))
                                .frame(width: 30, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(icon == choice ? colorForTrackerName(colorName).opacity(0.25) : Color.gray.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7)
                                        .stroke(icon == choice ? colorForTrackerName(colorName) : Color.gray.opacity(0.15), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    ForEach(trackerColorNames, id: \.self) { cName in
                        Button {
                            colorName = cName
                        } label: {
                            Circle()
                                .fill(colorForTrackerName(cName))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Circle()
                                        .stroke(colorName == cName ? Color.primary : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let cat = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
                    store.addTracker(
                        name: trimmed,
                        category: cat.isEmpty ? (category.isEmpty ? "Custom" : category) : cat,
                        icon: icon,
                        colorName: colorName,
                        isCounter: isCounter,
                        target: target,
                        scheduleNote: scheduleNote.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    dismiss()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 520)
    }
}
