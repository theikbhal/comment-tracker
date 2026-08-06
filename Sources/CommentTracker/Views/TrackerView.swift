import SwiftUI

struct TrackerView: View {
    @EnvironmentObject var store: Store
    @State private var date = Date()
    @State private var showingManage = false
    @State private var showingAdd = false
    @State private var noteEditor: (trackerID: Int, day: String)?

    private var dayKey: String { dayString(date) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(store.trackerCategories, id: \.self) { category in
                        categorySection(category)
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingManage) {
            ManageTrackersView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAdd) {
            AddTrackerView()
                .environmentObject(store)
        }
        .sheet(item: $store.trackerToDetail) { tracker in
            TrackerDetailView(trackerID: tracker.id)
                .environmentObject(store)
        }
        .sheet(item: Binding(
            get: {
                noteEditor.map {
                    NoteEditorDraft(trackerID: $0.trackerID, day: $0.day)
                }
            },
            set: { noteEditor = $0.map { (trackerID: $0.trackerID, day: $0.day) } }
        )) { draft in
            DayEditorView(trackerID: draft.trackerID, day: draft.day)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tracker")
                    .font(.title.bold())
                Text("Daily routines & deen")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            dateNavigator
            Button {
                showingManage = true
            } label: {
                Label("Manage", systemImage: "switch.2")
            }
            Button {
                showingAdd = true
            } label: {
                Label("Add", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var dateNavigator: some View {
        HStack(spacing: 8) {
            Button {
                date = Calendar.current.date(byAdding: .day, value: -1, to: date) ?? date
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Button {
                date = Date()
            } label: {
                Text(dateKeyLabel)
                    .font(.headline)
                    .monospacedDigit()
            }
            .buttonStyle(.bordered)

            Button {
                date = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
    }

    private var dateKeyLabel: String {
        if Calendar.current.isDateInToday(date) {
            return "Today · \(dayKey)"
        }
        return dayKey
    }

    private func categorySection(_ category: String) -> some View {
        let trackers = store.trackersForCategory(category)
        guard !trackers.isEmpty else { return AnyView(EmptyView()) }
        let done = trackers.filter { store.isDone(trackerID: $0.id, on: dayKey) }.count
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(category)
                        .font(.headline)
                    Spacer()
                    Text("\(done)/\(trackers.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                VStack(spacing: 8) {
                    ForEach(trackers) { tracker in
                        TrackerRowView(
                            tracker: tracker,
                            date: date,
                            onOpenDetail: { store.trackerToDetail = tracker },
                            onEditNote: { noteEditor = (tracker.id, dayKey) }
                        )
                    }
                }
            }
            .padding(16)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.12), lineWidth: 1)
            )
        )
    }
}

struct NoteEditorDraft: Identifiable {
    let trackerID: Int
    let day: String
    var id: String { "\(trackerID)-\(day)" }
}

// MARK: - Row

struct TrackerRowView: View {
    @EnvironmentObject var store: Store
    let tracker: Tracker
    let date: Date
    let onOpenDetail: () -> Void
    let onEditNote: () -> Void

    private var dayKey: String { dayString(date) }
    private var count: Int { store.count(for: tracker.id, on: dayKey) }
    private var hasNote: Bool { !store.note(for: tracker.id, on: dayKey).isEmpty }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tracker.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(tracker.color.gradient, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(tracker.name)
                    .font(.subheadline.weight(.semibold))
                if !tracker.scheduleNote.isEmpty {
                    Text(tracker.scheduleNote)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onEditNote()
            } label: {
                Image(systemName: hasNote ? "note.text" : "note.text.badge.plus")
                    .font(.system(size: 14))
                    .foregroundStyle(hasNote ? tracker.color : .secondary)
            }
            .buttonStyle(.borderless)
            .help("Note for this day")

            if tracker.isCounter {
                counterControl
            } else {
                checkButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { onOpenDetail() }
    }

    private var checkButton: some View {
        Button {
            store.toggle(tracker.id, on: dayKey)
        } label: {
            Image(systemName: count > 0 ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(count > 0 ? tracker.color : Color.secondary)
        }
        .buttonStyle(.borderless)
        .help(count > 0 ? "Done — click to uncheck" : "Mark done")
    }

    private var counterControl: some View {
        HStack(spacing: 8) {
            Button {
                store.setCount(tracker.id, on: dayKey, count - 1)
            } label: {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.borderless)
            .disabled(count <= 0)

            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.headline)
                    .monospacedDigit()
                    .frame(minWidth: 40)
                Text("/ \(tracker.target)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Button {
                store.setCount(tracker.id, on: dayKey, count + 1)
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)

            ProgressView(value: Double(min(count, tracker.target)), total: Double(max(1, tracker.target)))
                .tint(tracker.color)
                .frame(width: 60)
        }
    }
}
