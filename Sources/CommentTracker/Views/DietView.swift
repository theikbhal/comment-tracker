import SwiftUI
import AppKit

struct DietView: View {
    @EnvironmentObject var store: Store
    @State private var date = Date()
    @State private var meal: DietMeal = .breakfast
    @State private var food = ""
    @State private var note = ""
    @State private var searchText = ""
    @State private var editing: DietEntry?

    private var dayKey: String { dayString(date) }

    private var entries: [DietEntry] {
        var list = store.dietEntries(for: dayKey)
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.dietEntry($0, matches: searchText) }
        }
        return list
    }

    private func entries(for m: DietMeal) -> [DietEntry] {
        entries.filter { $0.meal == m }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    composeBox
                    summary
                    if entries.isEmpty {
                        emptyState
                    } else {
                        ForEach(DietMeal.allCases) { m in
                            let items = entries(for: m)
                            if !items.isEmpty {
                                mealSection(m, items)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 700, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(item: $editing) { entry in
            DietEditSheet(entry: entry) { food, note in
                store.updateDietEntry(id: entry.id, food: food, note: note)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Diet")
                    .font(.title.bold())
                Text("\(store.dietEntries(for: dayKey).count) entries today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            dateNavigator
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search diet…", text: $searchText)
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
        .frame(width: 200)
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
                Text(dateLabel)
                    .font(.subheadline.weight(.semibold))
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

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }

    private var composeBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Picker("", selection: $meal) {
                    ForEach(DietMeal.allCases) { m in
                        Label(m.displayName, systemImage: m.symbol).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: meal.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(meal.color.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextField("What did you eat?", text: $food)
                        .textFieldStyle(.plain)
                        .font(.body)
                    if !note.isEmpty || food.isEmpty == false {
                        TextField("Note (optional)", text: $note)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Spacer()
                        Button {
                            store.addDietEntry(day: dayKey, meal: meal, food: food, note: note)
                            food = ""
                            note = ""
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(meal.color)
                        .disabled(food.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
    }

    private var summary: some View {
        HStack(spacing: 10) {
            ForEach(DietMeal.allCases) { m in
                let count = entries(for: m).count
                HStack(spacing: 5) {
                    Image(systemName: m.symbol)
                        .font(.system(size: 11))
                        .foregroundStyle(m.color)
                    Text("\(count)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(m.color.opacity(0.1), in: Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 2)
    }

    private func mealSection(_ m: DietMeal, _ items: [DietEntry]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: m.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(m.color)
                Text(m.displayName)
                    .font(.headline)
                Spacer()
                Text("\(items.count) item\(items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 4)
            VStack(spacing: 0) {
                ForEach(items) { entry in
                    DietRow(entry: entry) {
                        editing = entry
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.14), lineWidth: 1)
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "takeoutbag.and.cup.and.straw")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("Nothing logged yet — add what you ate above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Row

struct DietRow: View {
    @EnvironmentObject var store: Store
    let entry: DietEntry
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.food)
                    .font(.callout.weight(.medium))
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Edit")
            Button {
                store.deleteDietEntry(entry.id)
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .help("Delete")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
        }
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit…", systemImage: "pencil")
            }
            Divider()
            Button(role: .destructive) {
                store.deleteDietEntry(entry.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Edit sheet

struct DietEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let entry: DietEntry
    let onSave: (String, String) -> Void

    @State private var food = ""
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Edit \(entry.meal.displayName)")
                .font(.title2.bold())
            TextField("Food", text: $food)
                .textFieldStyle(.roundedBorder)
            TextField("Note (optional)", text: $note)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    onSave(food, note)
                    dismiss()
                } label: {
                    Label("Save", systemImage: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .disabled(food.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            food = entry.food
            note = entry.note
        }
    }
}
