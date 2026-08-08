import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case today, bucket, focus, parallel, urgent, holding, projects, schedule, mindmap, blog, slack, calendar, year, weeks, challenge, roadmap, alarms, tools, dreams, features, table, airtable, pending, diet, family, followup, inspire, tracker, people, thoughts, videos, hosting, reddit, events, tree, faq, celebrations, wins, fails, notes, links, cards, pomodoro, deepwork, sprints, voice, history, help
    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .bucket: return "Buck Track"
        case .focus: return "Focus"
        case .parallel: return "Parallel"
        case .urgent: return "Urgent"
        case .holding: return "Holding Hand"
        case .projects: return "Projects"
        case .schedule: return "Schedule"
        case .mindmap: return "Mind Map"
        case .blog: return "Blog"
        case .slack: return "Slack"
        case .calendar: return "Calendar"
        case .year: return "Year"
        case .weeks: return "52 Weeks"
        case .challenge: return "Challenges"
        case .roadmap: return "Roadmap"
        case .alarms: return "Alarms"
        case .tools: return "Tools"
        case .dreams: return "Old Dreams"
        case .features: return "Feature Requests"
        case .table: return "Table Tracker"
        case .airtable: return "Mini Airtable"
        case .pending: return "Pending"
        case .diet: return "Diet"
        case .family: return "Family"
        case .followup: return "Follow-ups"
        case .inspire: return "Inspire"
        case .tracker: return "Tracker"
        case .people: return "People"
        case .thoughts: return "Thoughts"
        case .videos: return "Videos"
        case .hosting: return "Mini Videos"
        case .reddit: return "Reddit"
        case .events: return "Events"
        case .tree: return "Mini Tree"
        case .faq: return "FAQ"
        case .celebrations: return "Celebrations"
        case .wins: return "Wins"
        case .fails: return "Fails"
        case .notes: return "Notes"
        case .links: return "Links"
        case .cards: return "313 Cards"
        case .pomodoro: return "Pomodoro"
        case .deepwork: return "Deep Work"
        case .sprints: return "Sprints"
        case .voice: return "Voice Notes"
        case .history: return "History"
        case .help: return "Help"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "target"
        case .bucket: return "hammer.fill"
        case .focus: return "scope"
        case .parallel: return "square.split.3x1"
        case .urgent: return "flame.fill"
        case .holding: return "hand.raised.fill"
        case .projects: return "shippingbox.fill"
        case .schedule: return "calendar.badge.clock"
        case .mindmap: return "point.3.connected.trianglepath.dotted"
        case .blog: return "newspaper.fill"
        case .slack: return "bubble.left.and.bubble.right.fill"
        case .calendar: return "calendar"
        case .year: return "calendar.circle"
        case .weeks: return "calendar.badge.plus"
        case .challenge: return "bolt.fill"
        case .roadmap: return "map.fill"
        case .alarms: return "alarm.fill"
        case .tools: return "wrench.and.screwdriver.fill"
        case .dreams: return "moon.stars.fill"
        case .features: return "lightbulb.fill"
        case .table: return "tablecells"
        case .airtable: return "rectangle.3.group.fill"
        case .pending: return "hourglass"
        case .diet: return "fork.knife"
        case .family: return "person.2.fill"
        case .followup: return "arrow.triangle.2.circlepath"
        case .inspire: return "sparkles"
        case .tracker: return "checklist"
        case .people: return "person.2"
        case .thoughts: return "lightbulb"
        case .videos: return "play.rectangle"
        case .hosting: return "video.fill"
        case .reddit: return "bubble.left.and.bubble.right.fill"
        case .events: return "calendar.badge.clock"
        case .tree: return "tree"
        case .faq: return "questionmark.circle.fill"
        case .celebrations: return "party.popper.fill"
        case .wins: return "party.popper"
        case .fails: return "xmark.seal"
        case .notes: return "note.text"
        case .links: return "link"
        case .cards: return "square.grid.3x3"
        case .pomodoro: return "timer"
        case .deepwork: return "brain.head.profile"
        case .sprints: return "flag"
        case .voice: return "mic.fill"
        case .history: return "chart.bar.xaxis"
        case .help: return "questionmark.circle"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: Store
    @State private var selection: SidebarItem = .today
    @State private var showingAdd = false
    @State private var showingOnboarding = false
    @State private var showingSearch = false

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
            .safeAreaInset(edge: .bottom) {
                if selection == .today {
                    miniProgress
                }
            }
        } detail: {
            detail(for: selection)
        }
        .navigationTitle("Comment Tracker")
        .sheet(isPresented: $showingAdd) {
            AddCommentView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingSearch) {
            GlobalSearchView(
                onNavigate: { selection = $0 },
                onOpenTracker: { store.trackerToDetail = store.trackerByID($0) },
                onOpenPerson: { store.personToDetail = store.personByID($0) },
                onOpenVideo: { store.videoToDetail = store.videoByID($0) }
            )
            .environmentObject(store)
        }
        .onAppear {
            if !store.isOnboarded {
                showingOnboarding = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .addComment)) { _ in
            showingAdd = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSession)) { _ in
            store.toggleSession()
        }
        .onReceive(NotificationCenter.default.publisher(for: .search)) { _ in
            showingSearch = true
        }
    }

    @ViewBuilder
    private func detail(for item: SidebarItem) -> some View {
        switch item {
        case .today: TodayView()
        case .bucket: BuckTrackView()
        case .focus: FocusView()
        case .parallel: ParallelView()
        case .urgent: UrgentView()
        case .holding: HoldingView()
        case .projects: ProjectTrackerView()
        case .schedule: ScheduleView()
        case .mindmap: MiniMindMapView()
        case .blog: BlogView()
        case .slack: SlackView()
        case .calendar: CalendarView()
        case .year: YearView()
        case .weeks: WeekView()
        case .challenge: ChallengeView()
        case .roadmap: RoadmapView()
        case .alarms: AlarmsView()
        case .tools: ToolsView()
        case .dreams: DreamsView()
        case .features: FeatureRequestsView()
        case .table: TableTrackerView()
        case .airtable: AirtableView()
        case .pending: PendingListView()
        case .diet: DietView()
        case .family: FamilyView()
        case .followup: FollowUpView()
        case .inspire: InspireView()
        case .tracker: TrackerView()
        case .people: PeopleView()
        case .thoughts: ThoughtsView()
        case .videos: VideosView()
        case .hosting: HostedVideosView()
        case .reddit: RedditView()
        case .events: EventsView()
        case .tree: TreeView()
        case .faq: FaqView()
        case .celebrations: CelebrationsView()
        case .wins: WinsView()
        case .fails: FailsView()
        case .notes: InterstitialNotesView()
        case .links: LinksView()
        case .cards: Cards313View()
        case .pomodoro: PomodoroView()
        case .deepwork: DeepWorkView()
        case .sprints: SprintsView()
        case .voice: VoiceNotesView()
        case .history: HistoryView()
        case .help: HelpView()
        }
    }

    private var miniProgress: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.todayCount)/\(store.subGoal)")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
            }
            ProgressView(value: store.subGoalProgress)
                .tint(.blue)
        }
        .padding(12)
        .background(.bar)
    }
}
