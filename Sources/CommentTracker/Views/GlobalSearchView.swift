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

    private var calendarResults: [CalendarEvent] {
        store.calendarEvents.filter { store.calendarEvent($0, matches: query) }
    }

    private var yearResults: [YearCard] {
        store.yearCards.filter { store.yearCard($0, matches: query) }
    }

    private var weekResults: [WeekCard] {
        store.weekCards.filter { store.weekCard($0, matches: query) }
    }

    private var challengeResults: [Challenge] {
        store.challenges.filter { store.challenge($0, matches: query) }
    }

    private var roadmapResults: [RoadmapItem] {
        store.roadmap.filter { store.roadmapItem($0, matches: query) }
    }

    private var alarmResults: [AlarmItem] {
        store.alarms.filter { store.alarm($0, matches: query) }
    }

    private var toolResults: [Tool] {
        store.tools.filter { store.tool($0, matches: query) }
    }

    private var dreamResults: [Dream] {
        store.dreams.filter { store.dream($0, matches: query) }
    }

    private var featureResults: [FeatureRequest] {
        store.featureRequests.filter { store.featureRequest($0, matches: query) }
    }

    private var tableResults: [TableTracker] {
        store.tableTrackers.filter { store.tableTracker($0, matches: query) }
    }

    private var airtableResults: [Airtable] {
        store.airtables.filter { store.airtable($0, matches: query) }
    }

    private var hostedVideoResults: [HostedVideo] {
        store.hostedVideos.filter { store.hostedVideo($0, matches: query) }
    }

    private var redditResults: [RedditPost] {
        store.redditPosts.filter { store.redditPost($0, matches: query) }
    }

    private var eventResults: [EventShow] {
        store.events.filter { store.eventShow($0, matches: query) }
    }

    private var treeResults: [TreeNode] {
        store.treeNodes.filter { store.treeNode($0, matches: query) }
    }

    private var faqResults: [Faq] {
        store.faqs.filter { store.faq($0, matches: query) }
    }

    private var pendingResults: [PendingItem] {
        store.pendingItems.filter { store.pendingItem($0, matches: query) }
    }

    private var dietResults: [DietEntry] {
        store.dietEntries.filter { store.dietEntry($0, matches: query) }
    }

    private var familyResults: [FamilyMember] {
        store.familyMembers.filter { store.familyMember($0, matches: query) }
    }

    private var followUpResults: [FollowUp] {
        store.followUps.filter { store.followUp($0, matches: query) }
    }

    private var inspirationResults: [Inspiration] {
        store.inspirations.filter { store.inspiration($0, matches: query) }
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
                    if calendarResults.count > 0 {
                        section("Calendar", icon: "calendar") {
                            ForEach(calendarResults) { e in
                                row(icon: "calendar", color: mindMapColor(e.color), title: e.title, subtitle: "\(e.day)\(e.time.isEmpty ? "" : " · \(e.time)")") {
                                    dismiss()
                                    onNavigate(.calendar)
                                }
                            }
                        }
                    }
                    if yearResults.count > 0 {
                        section("Year", icon: "calendar.circle") {
                            ForEach(yearResults) { c in
                                row(icon: "calendar.circle", color: .teal, title: c.word.isEmpty ? c.monthName : c.word, subtitle: "\(c.monthName) · card \(c.slot)/12") {
                                    dismiss()
                                    onNavigate(.year)
                                }
                            }
                        }
                    }
                    if weekResults.count > 0 {
                        section("52 Weeks", icon: "calendar.badge.plus") {
                            ForEach(weekResults) { c in
                                row(icon: "calendar.badge.plus", color: .mint, title: c.title.isEmpty ? "Week \(c.slot) · \(c.monthName)" : c.title, subtitle: "\(c.dateRangeText) · WK \(c.slot)") {
                                    dismiss()
                                    onNavigate(.weeks)
                                }
                            }
                        }
                    }
                    if challengeResults.count > 0 {
                        section("Challenges", icon: "bolt.fill") {
                            ForEach(challengeResults) { c in
                                row(icon: "bolt.fill", color: c.status.color, title: c.title, subtitle: c.dateRangeText.isEmpty ? c.status.displayName : "\(c.status.displayName) · \(c.dateRangeText)") {
                                    dismiss()
                                    onNavigate(.challenge)
                                }
                            }
                        }
                    }
                    if roadmapResults.count > 0 {
                        section("Roadmap", icon: "map.fill") {
                            ForEach(roadmapResults) { r in
                                row(icon: "map.fill", color: r.priority.color, title: r.title, subtitle: "\(r.status.displayName)\(r.quarter.isEmpty ? "" : " · \(r.quarter)")") {
                                    dismiss()
                                    onNavigate(.roadmap)
                                }
                            }
                        }
                    }
                    if alarmResults.count > 0 {
                        section("Alarms", icon: "alarm.fill") {
                            ForEach(alarmResults) { a in
                                row(icon: "alarm.fill", color: .orange, title: a.label.isEmpty ? "Alarm" : a.label, subtitle: a.timeText) {
                                    dismiss()
                                    onNavigate(.alarms)
                                }
                            }
                        }
                    }
                    if toolResults.count > 0 {
                        section("Tools", icon: "wrench.and.screwdriver.fill") {
                            ForEach(toolResults) { t in
                                row(icon: "wrench.and.screwdriver.fill", color: .indigo, title: t.name, subtitle: t.link.isEmpty ? "Tool" : t.link) {
                                    dismiss()
                                    onNavigate(.tools)
                                }
                            }
                        }
                    }
                    if dreamResults.count > 0 {
                        section("Old Dreams", icon: "moon.stars.fill") {
                            ForEach(dreamResults) { d in
                                row(icon: "moon.stars.fill", color: .purple, title: d.title, subtitle: d.link.isEmpty ? "Dream" : d.link) {
                                    dismiss()
                                    onNavigate(.dreams)
                                }
                            }
                        }
                    }
                    if featureResults.count > 0 {
                        section("Feature Requests", icon: "lightbulb.fill") {
                            ForEach(featureResults) { f in
                                row(icon: "lightbulb.fill", color: .yellow, title: f.title, subtitle: f.app.isEmpty ? f.status.displayName : "\(f.app) · \(f.status.displayName)") {
                                    dismiss()
                                    onNavigate(.features)
                                }
                            }
                        }
                    }
                    if tableResults.count > 0 {
                        section("Table Tracker", icon: "tablecells") {
                            ForEach(tableResults) { t in
                                row(icon: "tablecells", color: .indigo, title: t.name, subtitle: "\(store.tableRows(for: t.id).count) rows") {
                                    dismiss()
                                    onNavigate(.table)
                                }
                            }
                        }
                    }
                    if airtableResults.count > 0 {
                        section("Mini Airtable", icon: "rectangle.3.group.fill") {
                            ForEach(airtableResults) { a in
                                row(icon: "rectangle.3.group.fill", color: .orange, title: a.name, subtitle: "\(store.airtableRows(for: a.id).count) rows") {
                                    dismiss()
                                    onNavigate(.airtable)
                                }
                            }
                        }
                    }
                    if hostedVideoResults.count > 0 {
                        section("Mini Videos", icon: "video.fill") {
                            ForEach(hostedVideoResults) { v in
                                row(icon: "video.fill", color: .red, title: v.title, subtitle: "\(store.hostedVideoComments(for: v.id).count) comments") {
                                    dismiss()
                                    onNavigate(.hosting)
                                }
                            }
                        }
                    }
                    if redditResults.count > 0 {
                        section("Reddit", icon: "bubble.left.and.bubble.right.fill") {
                            ForEach(redditResults) { p in
                                row(icon: "bubble.left.and.bubble.right.fill", color: .orange, title: p.title, subtitle: "\(p.subText) · \(store.redditComments(for: p.id).count) comments") {
                                    dismiss()
                                    onNavigate(.reddit)
                                }
                            }
                        }
                    }
                    if eventResults.count > 0 {
                        section("Events", icon: "calendar.badge.clock") {
                            ForEach(eventResults) { e in
                                row(icon: "calendar.badge.clock", color: .purple, title: e.title, subtitle: "\(store.episodes(for: e.id).count) episodes · \(e.subscribed ? "Subscribed" : "Not subscribed")") {
                                    dismiss()
                                    onNavigate(.events)
                                }
                            }
                        }
                    }
                    if treeResults.count > 0 {
                        section("Mini Tree", icon: "tree") {
                            ForEach(treeResults) { n in
                                row(icon: "tree", color: .green, title: n.title, subtitle: "\(store.treeDepth(of: n.id)) levels deep · \(store.treeChildren(of: n.id).count) children") {
                                    dismiss()
                                    onNavigate(.tree)
                                }
                            }
                        }
                    }
                    if faqResults.count > 0 {
                        section("FAQ", icon: "questionmark.circle.fill") {
                            ForEach(faqResults) { f in
                                row(icon: "questionmark.circle.fill", color: .purple, title: f.title, subtitle: "\(store.faqEntries(for: f.id).count) questions") {
                                    dismiss()
                                    onNavigate(.faq)
                                }
                            }
                        }
                    }
                    if pendingResults.count > 0 {
                        section("Pending", icon: "hourglass") {
                            ForEach(pendingResults) { p in
                                row(icon: "hourglass", color: .teal, title: p.title, subtitle: p.done ? "Done" : "Pending") {
                                    dismiss()
                                    onNavigate(.pending)
                                }
                            }
                        }
                    }
                    if dietResults.count > 0 {
                        section("Diet", icon: "fork.knife") {
                            ForEach(dietResults) { e in
                                row(icon: "fork.knife", color: .green, title: e.food, subtitle: "\(e.meal.displayName) · \(e.day)") {
                                    dismiss()
                                    onNavigate(.diet)
                                }
                            }
                        }
                    }
                    if familyResults.count > 0 {
                        section("Family", icon: "person.2.fill") {
                            ForEach(familyResults) { m in
                                row(icon: "person.2.fill", color: .green, title: m.name, subtitle: m.relation.isEmpty ? "Family" : m.relation) {
                                    dismiss()
                                    onNavigate(.family)
                                }
                            }
                        }
                    }
                    if followUpResults.count > 0 {
                        section("Follow-ups", icon: "arrow.triangle.2.circlepath") {
                            ForEach(followUpResults) { f in
                                row(icon: "arrow.triangle.2.circlepath", color: .blue, title: f.title, subtitle: f.done ? "Done" : (f.hasDate ? f.dateText : "Follow-up")) {
                                    dismiss()
                                    onNavigate(.followup)
                                }
                            }
                        }
                    }
                    if inspirationResults.count > 0 {
                        section("Inspire", icon: "sparkles") {
                            ForEach(inspirationResults) { i in
                                row(icon: "sparkles", color: .pink, title: i.text, subtitle: i.source.isEmpty ? "Inspiration" : i.source) {
                                    dismiss()
                                    onNavigate(.inspire)
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
                    if trimmedQuery.isEmpty || (navResults.isEmpty && trackerResults.isEmpty && personResults.isEmpty && videoResults.isEmpty && thoughtResults.isEmpty && winResults.isEmpty && failResults.isEmpty && noteResults.isEmpty && buckResults.isEmpty && focusResults.isEmpty && parallelResults.isEmpty && holdingResults.isEmpty && urgentResults.isEmpty && mindMapResults.isEmpty && mindMapNodeResults.isEmpty && blogResults.isEmpty && slackChannelResults.isEmpty && slackMessageResults.isEmpty && calendarResults.isEmpty && yearResults.isEmpty && weekResults.isEmpty && challengeResults.isEmpty && roadmapResults.isEmpty && alarmResults.isEmpty && toolResults.isEmpty && dreamResults.isEmpty && featureResults.isEmpty && tableResults.isEmpty && airtableResults.isEmpty && hostedVideoResults.isEmpty && redditResults.isEmpty && eventResults.isEmpty && treeResults.isEmpty && faqResults.isEmpty && pendingResults.isEmpty && dietResults.isEmpty && familyResults.isEmpty && followUpResults.isEmpty && inspirationResults.isEmpty && projectResults.isEmpty && deepWorkResults.isEmpty && scheduleResults.isEmpty && cardResults.isEmpty && sprintResults.isEmpty && linkResults.isEmpty) {
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
            Text("\(calendarResults.count) calendar")
            Text("·")
            Text("\(yearResults.count) year")
            Text("·")
            Text("\(weekResults.count) weeks")
            Text("·")
            Text("\(challengeResults.count) challenges")
            Text("·")
            Text("\(roadmapResults.count) roadmap")
            Text("·")
            Text("\(alarmResults.count) alarms")
            Text("·")
            Text("\(toolResults.count) tools")
            Text("·")
            Text("\(dreamResults.count) dreams")
            Text("·")
            Text("\(featureResults.count) requests")
            Text("·")
            Text("\(tableResults.count) tables")
            Text("·")
            Text("\(airtableResults.count) airtables")
            Text("·")
            Text("\(hostedVideoResults.count) videos")
            Text("·")
            Text("\(redditResults.count) posts")
            Text("·")
            Text("\(eventResults.count) events")
            Text("·")
            Text("\(treeResults.count) branches")
            Text("·")
            Text("\(faqResults.count) faqs")
            Text("·")
            Text("\(pendingResults.count) pending")
            Text("·")
            Text("\(dietResults.count) diet")
            Text("·")
            Text("\(familyResults.count) family")
            Text("·")
            Text("\(followUpResults.count) follow-ups")
            Text("·")
            Text("\(inspirationResults.count) inspiration")
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
            Text(trimmedQuery.isEmpty ? "Type to search tabs, buckets, focus, parallel, urgent, holding, mind maps, blog, slack, calendar, projects, schedule, trackers, people, videos, thoughts, wins, fails, notes, cards, deep work, sprints and links" : "No results")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
