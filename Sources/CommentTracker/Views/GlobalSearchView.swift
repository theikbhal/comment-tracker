import SwiftUI

struct GlobalSearchView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    let onNavigate: (SidebarItem) -> Void
    let onOpenTracker: (Int) -> Void
    let onOpenPerson: (Int) -> Void
    let onOpenVideo: (Int) -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var navResults: [SidebarItem] {
        guard !trimmedQuery.isEmpty else { return SidebarItem.allCases }
        return SidebarItem.allCases.filter { $0.title.lowercased().contains(trimmedQuery.lowercased()) }
    }

    private var trackerResults: [Tracker] {
        store.enabledTrackers.filter { store.tracker($0, matches: query) }
    }

    private var personResults: [Person] {
        store.people.filter { store.person($0, matches: query) }
    }

    private var videoResults: [Video] {
        store.videos.filter { store.video($0, matches: query) }
    }

    private var thoughtResults: [Thought] {
        store.thoughts.filter { store.thought($0, matches: query) }
    }

    private var winResults: [Win] {
        store.wins.filter { store.win($0, matches: query) }
    }

    private var cardResults: [WordCard] {
        store.cards.filter { store.card($0, matches: query) }
    }

    private var sprintResults: [Sprint] {
        store.sprints.filter { store.sprint($0, matches: query) }
    }

    private var linkResults: [LinkItem] {
        store.links.filter { store.link($0, matches: query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !trimmedQuery.isEmpty {
                        summaryRow
                    }
                    if navResults.count > 0 {
                        section("Navigate", icon: "arrow.up.forward.square") {
                            ForEach(navResults) { item in
                                row(icon: item.symbol, color: .blue, title: item.title, subtitle: "Open \(item.title)") {
                                    dismiss()
                                    onNavigate(item)
                                }
                            }
                        }
                    }
                    if trackerResults.count > 0 {
                        section("Trackers", icon: "checklist") {
                            ForEach(trackerResults) { t in
                                row(icon: t.icon, color: t.color, title: t.name, subtitle: t.category) {
                                    dismiss()
                                    onOpenTracker(t.id)
                                }
                            }
                        }
                    }
                    if personResults.count > 0 {
                        section("People", icon: "person.2") {
                            ForEach(personResults) { p in
                                row(icon: "person.crop.circle", color: .blue, title: p.name, subtitle: p.stage.displayName) {
                                    dismiss()
                                    onOpenPerson(p.id)
                                }
                            }
                        }
                    }
                    if videoResults.count > 0 {
                        section("Videos", icon: "play.rectangle") {
                            ForEach(videoResults) { v in
                                row(icon: v.platform.symbol, color: v.platform.color, title: v.title, subtitle: v.stage.displayName) {
                                    dismiss()
                                    onOpenVideo(v.id)
                                }
                            }
                        }
                    }
                    if thoughtResults.count > 0 {
                        section("Thoughts", icon: "lightbulb") {
                            ForEach(thoughtResults) { th in
                                row(icon: "lightbulb", color: th.list.color, title: th.title, subtitle: th.list.displayName) {
                                    dismiss()
                                    onNavigate(.thoughts)
                                }
                            }
                        }
                    }
                    if winResults.count > 0 {
                        section("Wins", icon: "party.popper") {
                            ForEach(winResults) { w in
                                row(icon: "party.popper.fill", color: .orange, title: w.text, subtitle: "Win · \(w.createdAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.wins)
                                }
                            }
                        }
                    }
                    if cardResults.count > 0 {
                        section("313 Cards", icon: "square.grid.3x3") {
                            ForEach(cardResults) { c in
                                row(icon: "square.grid.3x3", color: .purple, title: c.word, subtitle: c.groupName.isEmpty ? "313 Cards" : c.groupName) {
                                    dismiss()
                                    onNavigate(.cards)
                                }
                            }
                        }
                    }
                    if sprintResults.count > 0 {
                        section("Sprints", icon: "flag") {
                            ForEach(sprintResults) { s in
                                row(icon: "flag", color: .orange, title: s.name, subtitle: s.done ? "Done · Sprint" : "Open · Sprint") {
                                    dismiss()
                                    onNavigate(.sprints)
                                }
                            }
                        }
                    }
                    if linkResults.count > 0 {
                        section("Links", icon: "link") {
                            ForEach(linkResults) { l in
                                row(icon: "link", color: .blue, title: l.label.isEmpty ? l.url : l.label, subtitle: l.url) {
                                    dismiss()
                                    onNavigate(.links)
                                }
                            }
                        }
                    }
                    if trimmedQuery.isEmpty || (navResults.isEmpty && trackerResults.isEmpty && personResults.isEmpty && videoResults.isEmpty && thoughtResults.isEmpty && winResults.isEmpty && cardResults.isEmpty && sprintResults.isEmpty && linkResults.isEmpty) {
                        emptyState
                    }
                }
                .padding(14)
            }
        }
        .frame(width: 560, height: 480)
        .onAppear {
            searchFocused = true
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search everything — ⌘K", text: $query)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($searchFocused)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Text("esc")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
        }
        .padding(14)
        .onExitCommand {
            dismiss()
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 8) {
            Text("\(trackerResults.count) trackers")
            Text("·")
            Text("\(personResults.count) people")
            Text("·")
            Text("\(videoResults.count) videos")
            Text("·")
            Text("\(thoughtResults.count) thoughts")
            Text("·")
            Text("\(winResults.count) wins")
            Text("·")
            Text("\(cardResults.count) cards")
            Text("·")
            Text("\(sprintResults.count) sprints")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private func section<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(.secondary)
            VStack(spacing: 6) {
                content()
            }
        }
    }

    private func row(icon: String, color: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(color.gradient, in: RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(8)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(trimmedQuery.isEmpty ? "Type to search tabs, trackers, people, videos, thoughts, wins, cards, sprints and links" : "No results")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
