import SwiftUI
import AppKit

private struct CardTopKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] { [:] }
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

struct PeopleView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            BoardView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingAdd) {
            AddPersonView()
                .environmentObject(store)
        }
        .sheet(item: $store.personToDetail) { person in
            PersonDetailView(personID: person.id)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("People")
                    .font(.title.bold())
                Text("\(store.totalPeople) of \(store.peopleGoal) tracked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: Double(store.totalPeople), total: Double(max(1, store.peopleGoal)))
                .tint(.green)
                .frame(maxWidth: 180)
            Spacer()
            Button {
                showingAdd = true
            } label: {
                Label("Add Person", systemImage: "person.badge.plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }
}

// MARK: - Board

struct BoardView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(PersonStage.allCases) { stage in
                    ColumnView(stage: stage)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Column

struct ColumnView: View {
    @EnvironmentObject var store: Store
    let stage: PersonStage

    @State private var isDropTargeted = false
    @State private var cardTops: [Int: CGFloat] = [:]

    private var columnSpaceName: String { "col-\(stage.rawValue)" }
    private var people: [Person] { store.peopleForStage(stage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(people) { person in
                        PersonCardView(person: person)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: CardTopKey.self,
                                        value: [person.id: geo.frame(in: .named(columnSpaceName)).minY]
                                    )
                                }
                            )
                    }
                    if people.isEmpty {
                        emptyHint
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 232)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(stage.isHolding ? Color.gray.opacity(0.05) : stage.color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDropTargeted ? stage.color : Color.gray.opacity(0.14), lineWidth: isDropTargeted ? 2 : 1)
        )
        .coordinateSpace(name: columnSpaceName)
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers, location in
            handleDrop(providers, location: location)
        }
        .onPreferenceChange(CardTopKey.self) { value in
            cardTops = value
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: stage.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(stage.color)
                Text(stage.displayName)
                    .font(.headline)
                Spacer()
                Text("\(people.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(stage.group)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 4)
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Image(systemName: stage.symbol)
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text("Drag cards here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .contentShape(Rectangle())
    }

    private func handleDrop(_ providers: [NSItemProvider], location: CGPoint) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? String, let id = Int(idString) else { return }
            Task { @MainActor in
                let index = self.insertionIndex(for: location.y)
                self.store.movePerson(id, to: stage, at: index)
            }
        }
        return true
    }

    private func insertionIndex(for locationY: CGFloat) -> Int {
        var index = people.count
        for (i, p) in people.enumerated() {
            if let top = cardTops[p.id], top > locationY {
                index = i
                break
            }
        }
        return index
    }
}

// MARK: - Card

struct PersonCardView: View {
    @EnvironmentObject var store: Store
    let person: Person

    private var personLinks: [PersonLink] { store.links(for: person.id) }
    private var personComments: [PersonComment] { store.comments(for: person.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Text(person.name)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                Spacer()
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !person.brief.isEmpty {
                Text(person.brief)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            HStack(spacing: 8) {
                if personComments.count > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 9))
                        Text("\(personComments.count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                HStack(spacing: 5) {
                    ForEach(Array(personLinks.prefix(3))) { link in
                        Image(systemName: link.kind.symbol)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    if personLinks.count > 3 {
                        Text("+\(personLinks.count - 3)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                Spacer()
                Text(person.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(person.stage.color)
                .frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(count: 2) {
            store.personToDetail = person
        }
        .onDrag {
            return NSItemProvider(object: "\(person.id)" as NSString)
        }
    }
}

// MARK: - Add Person

struct AddPersonView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brief = ""
    @State private var stage: PersonStage = .holding

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Person")
                .font(.title2.bold())
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
            TextField("Brief — who are they, what's the angle", text: $brief)
                .textFieldStyle(.roundedBorder)
            VStack(alignment: .leading, spacing: 6) {
                Text("List")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("List", selection: $stage) {
                    ForEach(PersonStage.allCases) { s in
                        Text("\(s.group) — \(s.displayName)").tag(s)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    store.addPerson(name: name, brief: brief, stage: stage)
                    dismiss()
                } label: {
                    Label("Add", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
