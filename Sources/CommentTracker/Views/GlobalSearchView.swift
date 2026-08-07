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

    private var failResults: [Fail] {
        store.fails.filter { store.fail($0, matches: query) }
    }

    private var noteResults: [InterNote] {
        store.interNotes.filter { store.interNote($0, matches: query) }
    }

    private var buckResults: [Buck] {
        store.bucks.filter { store.buck($0, matches: query) }
    }

    private var focusResults: [Focus] {
        store.focusSessions.filter { store.focus($0, matches: query) }
    }

    private var parallelResults: [ParallelItem] {
        store.parallel.filter { store.parallelItem($0, matches: query) }
    }

    private var projectResults: [Project] {
        store.projects.filter { store.project($0, matches: query) }
    }

    private var deepWorkResults: [DeepWorkSession] {
        store.deepWork.filter { store.deepWork($0, matches: query) }
    }

    private var scheduleResults: [ScheduleEntry] {
        store.schedule.filter { store.schedule($0, matches: query) }
    }

    private var holdingResults: [HoldingItem] {
        store.holding.filter { store.holdingItem($0, matches: query) }
    }

    private var urgentResults: [UrgentItem] {
        store.urgent.filter { store.urgentItem($0, matches: query) }
    }

    private var mindMapResults: [MindMap] {
        store.mindMaps.filter { store.mindMap($0, matches: query) }
    }

    private var mindMapNodeResults: [MindMapNode] {
        store.mindMapNodes.filter { store.mindMapNode($0, matches: query) }
    }

    private var blogResults: [BlogPost] {
        store.blogPosts.filter { store.blogPost($0, matches: query) }
    }

    private var slackChannelResults: [SlackChannel] {
        store.slackChannels.filter { store.slackChannel($0, matches: query) }
    }

    private var slackMessageResults: [SlackMessage] {
        store.slackMessages.filter { store.slackMessage($0, matches: query) }
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
                    if buckResults.count > 0 {
                        section("Buck Track", icon: "hammer.fill") {
                            ForEach(buckResults) { b in
                                row(icon: "hammer.fill", color: b.status.color, title: b.title, subtitle: b.status.displayName) {
                                    dismiss()
                                    onNavigate(.bucket)
                                }
                            }
                        }
                    }
                    if focusResults.count > 0 {
                        section("Focus", icon: "scope") {
                            ForEach(focusResults) { f in
                                row(icon: "scope", color: .indigo, title: f.text, subtitle: f.isActive ? "Active focus · \(f.startedAt.formatted(date: .abbreviated, time: .omitted))" : "Focus · \(f.startedAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.focus)
                                }
                            }
                        }
                    }
                    if parallelResults.count > 0 {
                        section("Parallel", icon: "square.split.3x1") {
                            ForEach(parallelResults) { p in
                                row(icon: "square.split.3x1", color: laneColor(p.lane), title: p.text, subtitle: "Parallel · \(laneLabel(p.lane))") {
                                    dismiss()
                                    onNavigate(.parallel)
                                }
                            }
                        }
                    }
                    if projectResults.count > 0 {
                        section("Projects", icon: "shippingbox.fill") {
                            ForEach(projectResults) { pr in
                                row(icon: "shippingbox.fill", color: pr.status.color, title: pr.name, subtitle: "Project · \(pr.status.displayName)") {
                                    dismiss()
                                    onNavigate(.projects)
                                }
                            }
                        }
                    }
                    if deepWorkResults.count > 0 {
                        section("Deep Work", icon: "brain.head.profile") {
                            ForEach(deepWorkResults) { d in
                                row(icon: "brain.head.profile", color: .indigo, title: "\(d.minutes)-min block", subtitle: d.completed ? "Completed deep work · \(d.startedAt.formatted(date: .abbreviated, time: .omitted))" : "Deep work · \(d.startedAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.deepwork)
                                }
                            }
                        }
                    }
                    if scheduleResults.count > 0 {
                        section("Schedule", icon: "calendar.badge.clock") {
                            ForEach(scheduleResults) { s in
                                row(icon: "calendar.badge.clock", color: .teal, title: s.task, subtitle: "\(dayName(s.day)) · \(scheduleSlotNames[s.slot])") {
                                    dismiss()
                                    onNavigate(.schedule)
                                }
                            }
                        }
                    }
                    if holdingResults.count > 0 {
                        section("Holding Hand", icon: "hand.raised.fill") {
                            ForEach(holdingResults) { h in
                                row(icon: "hand.raised.fill", color: .teal, title: h.text, subtitle: h.done ? "Released · \(h.createdAt.formatted(date: .abbreviated, time: .omitted))" : "Held · \(h.createdAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.holding)
                                }
                            }
                        }
                    }
                    if urgentResults.count > 0 {
                        section("Urgent", icon: "flame.fill") {
                            ForEach(urgentResults) { u in
                                row(icon: "flame.fill", color: u.urgency.color, title: u.text, subtitle: u.done ? "\(u.urgency.label) · done" : "\(u.urgency.label) · \(u.createdAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.urgent)
                                }
                            }
                        }
                    }
                    if mindMapResults.count > 0 || mindMapNodeResults.count > 0 {
                        section("Mind Map", icon: "point.3.connected.trianglepath.dotted") {
                            ForEach(mindMapResults) { m in
                                row(icon: "point.3.connected.trianglepath.dotted", color: .purple, title: m.title, subtitle: "Map · \(m.updatedAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.mindmap)
                                }
                            }
                            ForEach(mindMapNodeResults) { n in
                                row(icon: "point.3.connected.trianglepath.dotted", color: mindMapColor(n.color), title: n.text, subtitle: "Mind map node") {
                                    dismiss()
                                    onNavigate(.mindmap)
                                }
                            }
                        }
                    }
                    if blogResults.count > 0 {
                        section("Blog", icon: "newspaper.fill") {
                            ForEach(blogResults) { b in
                                row(icon: "newspaper.fill", color: b.status.color, title: b.title, subtitle: "\(b.status.displayName) · \(b.updatedAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.blog)
                                }
                            }
                        }
                    }
                    if slackChannelResults.count > 0 || slackMessageResults.count > 0 {
                        section("Slack", icon: "bubble.left.and.bubble.right.fill") {
                            ForEach(slackChannelResults) { c in
                                row(icon: "hash", color: mindMapColor(c.color), title: c.displayName, subtitle: "Channel") {
                                    dismiss()
                                    onNavigate(.slack)
                                }
                            }
                            ForEach(slackMessageResults) { m in
                                row(icon: "bubble.left", color: .teal, title: m.text, subtitle: "\(m.author) · \(m.createdAt.formatted(date: .abbreviated, time: .shortened))") {
                                    dismiss()
                                    onNavigate(.slack)
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
                    if failResults.count > 0 {
                        section("Fails", icon: "xmark.seal") {
                            ForEach(failResults) { f in
                                row(icon: "xmark.seal.fill", color: .red, title: f.text, subtitle: "Fail · \(f.createdAt.formatted(date: .abbreviated, time: .omitted))") {
                                    dismiss()
                                    onNavigate(.fails)
                                }
                            }
                        }
                    }
                    if noteResults.count > 0 {
                        section("Notes", icon: "note.text") {
                            ForEach(noteResults) { n in
                                row(icon: "note.text", color: .indigo, title: n.text, subtitle: n.createdAt.formatted(date: .abbreviated, time: .shortened)) {
                                    dismiss()
                                    onNavigate(.notes)
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
                    if trimmedQuery.isEmpty || (navResults.isEmpty && trackerResults.isEmpty && personResults.isEmpty && videoResults.isEmpty && thoughtResults.isEmpty && winResults.isEmpty && failResults.isEmpty && noteResults.isEmpty && buckResults.isEmpty && focusResults.isEmpty && parallelResults.isEmpty && holdingResults.isEmpty && urgentResults.isEmpty && mindMapResults.isEmpty && mindMapNodeResults.isEmpty && blogResults.isEmpty && slackChannelResults.isEmpty && slackMessageResults.isEmpty && projectResults.isEmpty && deepWorkResults.isEmpty && scheduleResults.isEmpty && cardResults.isEmpty && sprintResults.isEmpty && linkResults.isEmpty) {
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
            Text("\(failResults.count) fails")
            Text("·")
            Text("\(noteResults.count) notes")
            Text("·")
            Text("\(buckResults.count) buckets")
            Text("·")
            Text("\(focusResults.count) focus")
            Text("·")
            Text("\(parallelResults.count) parallel")
            Text("·")
            Text("\(projectResults.count) projects")
            Text("·")
            Text("\(deepWorkResults.count) deep work")
            Text("·")
            Text("\(scheduleResults.count) schedule")
            Text("·")
            Text("\(holdingResults.count) holding")
            Text("·")
            Text("\(urgentResults.count) urgent")
            Text("·")
            Text("\(mindMapResults.count + mindMapNodeResults.count) mind map")
            Text("·")
            Text("\(blogResults.count) blog")
            Text("·")
            Text("\(slackChannelResults.count + slackMessageResults.count) slack")
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
            Text(trimmedQuery.isEmpty ? "Type to search tabs, buckets, focus, parallel, urgent, holding, mind maps, blog, slack, projects, schedule, trackers, people, videos, thoughts, wins, fails, notes, cards, deep work, sprints and links" : "No results")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
