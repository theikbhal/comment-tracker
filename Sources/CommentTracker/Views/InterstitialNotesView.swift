import SwiftUI
import AppKit

struct InterstitialNotesView: View {
    @EnvironmentObject var store: Store
    @State private var draft = ""
    @State private var searchText = ""

    private var notes: [InterNote] {
        let base = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? store.interNotes
            : store.interNotes.filter { store.interNote($0, matches: searchText) }
        return base
    }

    private var groups: [(day: Date, notes: [InterNote])] {
        guard !notes.isEmpty else { return [] }
        let cal = Calendar.current
        var result: [(day: Date, notes: [InterNote])] = []
        var currentDay = cal.startOfDay(for: notes[0].createdAt)
        var current: [InterNote] = []
        for n in notes {
            let day = cal.startOfDay(for: n.createdAt)
            if day != currentDay && !current.isEmpty {
                result.append((currentDay, current))
                current = []
                currentDay = day
            }
            current.append(n)
        }
        if !current.isEmpty { result.append((currentDay, current)) }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 22) {
                    composeBox
                    if notes.isEmpty {
                        emptyState
                    } else {
                        ForEach(groups.indices, id: \.self) { i in
                            daySection(groups[i])
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Interstitial Notes")
                    .font(.title.bold())
                Text("\(store.interNotes.count) check-ins logged — what are you doing right now?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search notes…", text: $searchText)
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

    private var composeBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "note.text")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.indigo.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 54)
                        .overlay(alignment: .topLeading) {
                            if draft.isEmpty {
                                Text("Pause and write what you're doing right now…")
                                    .font(.body)
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 7)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                    HStack {
                        Text("\(draft.count)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        Spacer()
                        Button {
                            store.addInterNote(draft)
                            draft = ""
                        } label: {
                            Label("Log check-in", systemImage: "note.text.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    private func daySection(_ group: (day: Date, notes: [InterNote])) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(dayLabel(group.day))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            VStack(spacing: 0) {
                ForEach(group.notes) { note in
                    NotRowView(note: note)
                }
            }
            .background(
                RuledPaper()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.14), lineWidth: 1)
            )
        }
    }

    private func dayLabel(_ day: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(day) { return "Today" }
        if cal.isDateInYesterday(day) { return "Yesterday" }
        if cal.isDate(day, equalTo: Date(), toGranularity: .year) {
            return day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "note.text")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text("No check-ins yet — log what you're working on right now")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Notebook line

struct NotRowView: View {
    @EnvironmentObject var store: Store
    let note: InterNote

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(note.createdAt.formatted(date: .omitted, time: .shortened))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            Text(note.text)
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
            Button {
                store.deleteInterNote(note.id)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
            .help("Delete note")
        }
        .padding(.leading, 56)
        .padding(.trailing, 12)
        .padding(.vertical, 10)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.12))
                .frame(height: 1)
                .offset(y: 0)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Ruled notebook paper

struct RuledPaper: View {
    private let spacing: CGFloat = 26
    private let margin: CGFloat = 44

    var body: some View {
        Canvas { context, size in
            var y = spacing
            while y < size.height {
                let line = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(line, with: .color(Color.red.opacity(0.14)), lineWidth: 1)
                y += spacing
            }
            let marginLine = Path { p in
                p.move(to: CGPoint(x: margin, y: 0))
                p.addLine(to: CGPoint(x: margin, y: size.height))
            }
            context.stroke(marginLine, with: .color(Color.red.opacity(0.2)), lineWidth: 1)
        }
        .background(Color(calRuled))
    }

    private var calRuled: NSColor {
        NSColor(calibratedWhite: 0.99, alpha: 1)
    }
}