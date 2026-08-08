import Foundation
import SwiftUI
import UserNotifications
import AVFoundation

@MainActor
final class Store: ObservableObject {
    static let shared = Store()

    private let db = DatabaseManager.shared

    @Published var goal: Int = 313
    @Published var subGoal: Int = 30
    @Published var peopleGoal: Int = 313
    @Published var isOnboarded: Bool = false
    @Published var comments: [Comment] = []
    @Published var sessions: [Session] = []
    @Published var activeSession: Session?
    @Published var now = Date()

    @Published var people: [Person] = []
    @Published var peopleLinks: [PersonLink] = []
    @Published var peopleComments: [PersonComment] = []
    @Published var personToDetail: Person?

    @Published var videos: [Video] = []
    @Published var videoComments: [VideoComment] = []
    @Published var videoToDetail: Video?

    @Published var thoughts: [Thought] = []

    @Published var wins: [Win] = []
    @Published var fails: [Fail] = []
    @Published var interNotes: [InterNote] = []
    @Published var bucks: [Buck] = []
    @Published var focusSessions: [Focus] = []
    @Published var parallel: [ParallelItem] = []
    @Published var projects: [Project] = []
    @Published var longTermProjects: [LongTermProject] = []
    @Published var longTermMilestones: [LongTermMilestone] = []
    @Published var longTermComments: [LongTermComment] = []
    @Published var deepWork: [DeepWorkSession] = []
    @Published var schedule: [ScheduleEntry] = []
    @Published var holding: [HoldingItem] = []
    @Published var urgent: [UrgentItem] = []
    @Published var mindMaps: [MindMap] = []
    @Published var mindMapNodes: [MindMapNode] = []
    @Published var blogPosts: [BlogPost] = []
    @Published var slackChannels: [SlackChannel] = []
    @Published var slackMessages: [SlackMessage] = []
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var yearCards: [YearCard] = []
    @Published var weekCards: [WeekCard] = []
    @Published var audioNotes: [AudioNote] = []
    @Published var audioNoteComments: [AudioNoteComment] = []
    @Published var celebrations: [Celebration] = []
    @Published var celebrationComments: [CelebrationComment] = []
    @Published var celebrationNotes: String = ""
    @Published var challenges: [Challenge] = []
    @Published var challengeComments: [ChallengeComment] = []
    @Published var challengePrerequisiteLinks: [ChallengePrerequisiteLink] = []
    @Published var alarms: [AlarmItem] = []
    @Published var tools: [Tool] = []
    @Published var dreams: [Dream] = []
    @Published var featureRequests: [FeatureRequest] = []
    @Published var featureRequestComments: [FeatureRequestComment] = []
    @Published var tableTrackers: [TableTracker] = []
    @Published var tableRows: [TableRow] = []
    @Published var tableCells: [TableCell] = []
    @Published var pendingItems: [PendingItem] = []
    @Published var dietEntries: [DietEntry] = []
    @Published var familyMembers: [FamilyMember] = []
    @Published var familyComments: [FamilyComment] = []
    @Published var followUps: [FollowUp] = []
    @Published var inspirations: [Inspiration] = []
    @Published var airtables: [Airtable] = []
    @Published var airtableColumns: [AirtableColumn] = []
    @Published var airtableRows: [AirtableRow] = []
    @Published var airtableCells: [AirtableCell] = []
    @Published var hostedVideos: [HostedVideo] = []
    @Published var hostedVideoComments: [HostedVideoComment] = []
    @Published var redditPosts: [RedditPost] = []
    @Published var redditComments: [RedditComment] = []
    @Published var roadmap: [RoadmapItem] = []
    @Published var events: [EventShow] = []
    @Published var eventEpisodes: [EventEpisode] = []
    @Published var treeNodes: [TreeNode] = []
    @Published var faqs: [Faq] = []
    @Published var faqEntries: [FaqEntry] = []

    @Published var links: [LinkItem] = []
    @Published var cards: [WordCard] = []
    @Published var stacks: [Stack] = []
    @Published var stackItems: [StackItem] = []
    @Published var stackComments: [StackComment] = []
    @Published var pomodoros: [PomodoroSession] = []
    @Published var sprints: [Sprint] = []
    @Published var stories: [Story] = []
    @Published var storyTasks: [StoryTask] = []
    @Published var sprintToDetail: Sprint?

    @Published var trackers: [Tracker] = []
    @Published var trackerEntries: [TrackerEntry] = []
    @Published var trackerToDetail: Tracker?

    // Pomodoro timer (persists across tabs)
    @Published var pomodoroMode: PomodoroMode = .focus
    @Published var pomodoroRunning = false
    @Published var pomodoroEndTime: Date?
    @Published var pomodoroRemaining = PomodoroMode.focus.minutes * 60
    @Published var pomodoroSessionID: Int?
    @Published var pomodoroStartedAt = Date()

    // Deep work timer (persists across tabs)
    @Published var deepWorkRunning = false
    @Published var deepWorkSecondsLeft = 0
    @Published var deepWorkSelectedMinutes = 60
    @Published var deepWorkRunningSince = Date()
    @Published var deepWorkSessionNote = ""
    @Published var deepWorkTasks: [DeepWorkTask] = []

    // Deep work sound settings
    @Published var deepWorkSoundPreset = "Glass"
    @Published var deepWorkSoundCustomPath: String?
    @Published var deepWorkSoundDuration = 5
    private var deepWorkSound: NSSound?
    private var deepWorkSoundStopTask: Task<Void, Never>?

    // Floating timer window
    @Published var showFloatingTimer = false

    // Audio playback (Events "listen")
    private var audioPlayer: AVAudioPlayer?
    @Published var nowPlayingEpisodeID: Int?
    @Published var nowPlayingEventID: Int?
    @Published var nowPlayingAudioNoteID: Int?
    @Published var isPlaying = false
    @Published var audioPlaybackTime: TimeInterval = 0

    // Audio recording (Voice notes)
    private var audioRecorder: AVAudioRecorder?
    @Published var isRecordingAudio = false
    @Published var recordingAudioTime: TimeInterval = 0
    private var recordingStartedAt: Date?
    private var currentRecordingFilename: String?

    private var timer: Timer?

    init() {
        loadDeepWorkPrefs()
        load()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.now = Date()
                self?.tickTimers()
            }
        }
    }

    // MARK: - Loading

    func load() {
        let settings = db.allSettings
        if let g = settings["dailyGoal"].flatMap(Int.init), g > 0 {
            goal = g
        }
        if let s = settings["subGoal"].flatMap(Int.init), s > 0 {
            subGoal = s
        }
        if let p = settings["peopleGoal"].flatMap(Int.init), p > 0 {
            peopleGoal = p
        }
        isOnboarded = settings["onboarded"] == "true"
        seedPresetsIfNeeded()
        seedSlackIfNeeded()
        seedYearCardsIfNeeded()
        seedWeekCardsIfNeeded()
        refresh()
        syncCalendarReminders()
        syncAlarmNotifications()
    }

    func refresh() {
        comments = loadComments()
        sessions = loadSessions()
        activeSession = sessions.first { $0.isActive }
        people = loadPeople()
        peopleLinks = loadPersonLinks()
        peopleComments = loadPersonComments()
        videos = loadVideos()
        videoComments = loadVideoComments()
        thoughts = loadThoughts()
        wins = loadWins()
        fails = loadFails()
        interNotes = loadInterNotes()
        bucks = loadBucks()
        focusSessions = loadFocus()
        parallel = loadParallel()
        projects = loadProjects()
        longTermProjects = loadLongTermProjects()
        longTermMilestones = loadLongTermMilestones()
        longTermComments = loadLongTermComments()
        deepWork = loadDeepWork()
        deepWorkTasks = loadDeepWorkTasks()
        schedule = loadSchedule()
        holding = loadHolding()
        urgent = loadUrgent()
        mindMaps = loadMindMaps()
        mindMapNodes = loadMindMapNodes()
        blogPosts = loadBlogPosts()
        slackChannels = loadSlackChannels()
        slackMessages = loadSlackMessages()
        calendarEvents = loadCalendarEvents()
        yearCards = loadYearCards()
        weekCards = loadWeekCards()
        audioNotes = loadAudioNotes()
        audioNoteComments = loadAudioNoteComments()
        celebrations = loadCelebrations()
        celebrationComments = loadCelebrationComments()
        celebrationNotes = loadCelebrationNotes()
        challenges = loadChallenges()
        challengeComments = loadChallengeComments()
        challengePrerequisiteLinks = loadChallengePrerequisiteLinks()
        alarms = loadAlarms()
        tools = loadTools()
        dreams = loadDreams()
        featureRequests = loadFeatureRequests()
        featureRequestComments = loadFeatureRequestComments()
        tableTrackers = loadTableTrackers()
        tableRows = loadTableRows()
        tableCells = loadTableCells()
        pendingItems = loadPendingItems()
        dietEntries = loadDietEntries()
        familyMembers = loadFamilyMembers()
        familyComments = loadFamilyComments()
        followUps = loadFollowUps()
        inspirations = loadInspirations()
        airtables = loadAirtables()
        airtableColumns = loadAirtableColumns()
        airtableRows = loadAirtableRows()
        airtableCells = loadAirtableCells()
        hostedVideos = loadHostedVideos()
        hostedVideoComments = loadHostedVideoComments()
        redditPosts = loadRedditPosts()
        redditComments = loadRedditComments()
        events = loadEvents()
        eventEpisodes = loadEventEpisodes()
        treeNodes = loadTreeNodes()
        faqs = loadFaqs()
        faqEntries = loadFaqEntries()
        roadmap = loadRoadmap()
        links = loadLinks()
        cards = loadCards()
        stacks = loadStacks()
        stackItems = loadStackItems()
        stackComments = loadStackComments()
        pomodoros = loadPomodoros()
        sprints = loadSprints()
        stories = loadStories()
        storyTasks = loadStoryTasks()
        trackers = loadTrackers()
        trackerEntries = loadTrackerEntries()
    }

    // MARK: - Onboarding

    func finishOnboarding() {
        db.setSetting("dailyGoal", "\(goal)")
        db.setSetting("subGoal", "\(subGoal)")
        db.setSetting("onboarded", "true")
        isOnboarded = true
    }

    func updateGoal(_ newGoal: Int) {
        goal = max(1, newGoal)
        db.setSetting("dailyGoal", "\(goal)")
    }

    func updateSubGoal(_ newSubGoal: Int) {
        subGoal = max(1, newSubGoal)
        db.setSetting("subGoal", "\(subGoal)")
    }

    func updatePeopleGoal(_ newGoal: Int) {
        peopleGoal = max(1, newGoal)
        db.setSetting("peopleGoal", "\(peopleGoal)")
    }

    // MARK: - Comments

    func addComment(platform: Platform, body: String?, url: String?) {
        let createdAt = Date().timeIntervalSince1970
        let sessionID = activeSession?.id
        let trimmedBody = body?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = url?.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = db.execute(
            "INSERT INTO comments (platform, body, url, session_id, created_at) VALUES (?, ?, ?, ?, ?)",
            [platform.rawValue, trimmedBody, trimmedURL, sessionID, createdAt]
        )
        refresh()
    }

    // MARK: - Sessions

    func toggleSession() {
        if activeSession != nil {
            endSession()
        } else {
            startSession()
        }
    }

    func startSession() {
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO sessions (started_at, goal) VALUES (?, ?)", [now, goal])
        refresh()
    }

    func endSession() {
        guard let s = activeSession else { return }
        _ = db.execute("UPDATE sessions SET ended_at = ? WHERE id = ?", [Date().timeIntervalSince1970, s.id])
        refresh()
    }

    // MARK: - People

    var totalPeople: Int { people.count }

    func peopleForStage(_ stage: PersonStage) -> [Person] {
        people
            .filter { $0.stage == stage }
            .sorted { $0.position < $1.position }
    }

    func person(_ p: Person, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if p.name.lowercased().contains(q) { return true }
        if p.brief.lowercased().contains(q) { return true }
        if p.description.lowercased().contains(q) { return true }
        for link in peopleLinks where link.personId == p.id {
            if link.label.lowercased().contains(q) || link.url.lowercased().contains(q) {
                return true
            }
        }
        for comment in peopleComments where comment.personId == p.id {
            if comment.body.lowercased().contains(q) {
                return true
            }
        }
        return false
    }

    func personByID(_ id: Int) -> Person? {
        people.first { $0.id == id }
    }

    func links(for personID: Int) -> [PersonLink] {
        peopleLinks.filter { $0.personId == personID }
    }

    func comments(for personID: Int) -> [PersonComment] {
        peopleComments
            .filter { $0.personId == personID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addPerson(name: String, brief: String = "", stage: PersonStage = .holding) {
        let now = Date().timeIntervalSince1970
        let position = peopleForStage(stage).count
        _ = db.execute(
            "INSERT INTO people (name, brief, description, stage, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [name, brief, "", stage.rawValue, position, now, now]
        )
        refresh()
    }

    func updatePerson(id: Int, name: String? = nil, brief: String? = nil, description: String? = nil, stage: PersonStage? = nil) {
        guard let p = personByID(id) else { return }
        let newStage = stage ?? p.stage
        _ = db.execute(
            "UPDATE people SET name = ?, brief = ?, description = ?, stage = ?, updated_at = ? WHERE id = ?",
            [name ?? p.name, brief ?? p.brief, description ?? p.description, newStage.rawValue, Date().timeIntervalSince1970, id]
        )
        if let stage, stage != p.stage {
            reindexColumn(p.stage)
            reindexColumn(stage)
        }
        refresh()
    }

    func deletePerson(_ id: Int) {
        _ = db.execute("DELETE FROM people_links WHERE person_id = ?", [id])
        _ = db.execute("DELETE FROM people_comments WHERE person_id = ?", [id])
        _ = db.execute("DELETE FROM people WHERE id = ?", [id])
        refresh()
    }

    func movePerson(_ id: Int, to stage: PersonStage, at index: Int) {
        guard let p = personByID(id) else { return }
        let fromStage = p.stage
        var target = peopleForStage(stage)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(p, at: clamped)
        writeOrder(target, stage: stage)
        if fromStage != stage {
            writeOrder(peopleForStage(fromStage).filter { $0.id != id }, stage: fromStage)
        }
        refresh()
    }

    func reindexColumn(_ stage: PersonStage) {
        writeOrder(peopleForStage(stage), stage: stage)
    }

    private func writeOrder(_ ordered: [Person], stage: PersonStage) {
        for (i, person) in ordered.enumerated() {
            _ = db.execute("UPDATE people SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, person.id])
        }
    }

    func addPersonLink(personID: Int, label: String, url: String, kind: PersonLinkKind) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO people_links (person_id, label, url, kind) VALUES (?, ?, ?, ?)",
            [personID, label, trimmed, kind.rawValue]
        )
        refresh()
    }

    func deletePersonLink(_ id: Int) {
        _ = db.execute("DELETE FROM people_links WHERE id = ?", [id])
        refresh()
    }

    func addPersonComment(personID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO people_comments (person_id, body, created_at) VALUES (?, ?, ?)",
            [personID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    // MARK: - Videos

    var totalVideos: Int { videos.count }

    func videosForStage(_ stage: VideoStage) -> [Video] {
        videos
            .filter { $0.stage == stage }
            .sorted { $0.position < $1.position }
    }

    func videoByID(_ id: Int) -> Video? {
        videos.first { $0.id == id }
    }

    func videoComments(for videoID: Int) -> [VideoComment] {
        videoComments
            .filter { $0.videoId == videoID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func video(_ v: Video, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if v.title.lowercased().contains(q) { return true }
        if v.note.lowercased().contains(q) { return true }
        if v.description.lowercased().contains(q) { return true }
        if v.url.lowercased().contains(q) { return true }
        for comment in videoComments where comment.videoId == v.id {
            if comment.body.lowercased().contains(q) { return true }
        }
        return false
    }

    func addVideo(title: String, url: String, platform: VideoPlatform, stage: VideoStage = .holding) {
        let now = Date().timeIntervalSince1970
        let position = videosForStage(stage).count
        _ = db.execute(
            "INSERT INTO videos (title, note, description, platform, url, stage, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            [title, "", "", platform.rawValue, url, stage.rawValue, position, now, now]
        )
        refresh()
    }

    func updateVideo(id: Int, title: String? = nil, note: String? = nil, description: String? = nil, url: String? = nil, platform: VideoPlatform? = nil, stage: VideoStage? = nil) {
        guard let v = videoByID(id) else { return }
        let newStage = stage ?? v.stage
        _ = db.execute(
            "UPDATE videos SET title = ?, note = ?, description = ?, url = ?, platform = ?, stage = ?, updated_at = ? WHERE id = ?",
            [title ?? v.title, note ?? v.note, description ?? v.description, url ?? v.url, (platform ?? v.platform).rawValue, newStage.rawValue, Date().timeIntervalSince1970, id]
        )
        if let stage, stage != v.stage {
            reindexVideoColumn(v.stage)
            reindexVideoColumn(stage)
        }
        refresh()
    }

    func deleteVideo(_ id: Int) {
        _ = db.execute("DELETE FROM video_comments WHERE video_id = ?", [id])
        _ = db.execute("DELETE FROM videos WHERE id = ?", [id])
        refresh()
    }

    func moveVideo(_ id: Int, to stage: VideoStage, at index: Int) {
        guard let v = videoByID(id) else { return }
        let fromStage = v.stage
        var target = videosForStage(stage)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(v, at: clamped)
        writeVideoOrder(target, stage: stage)
        if fromStage != stage {
            writeVideoOrder(videosForStage(fromStage).filter { $0.id != id }, stage: fromStage)
        }
        refresh()
    }

    func reindexVideoColumn(_ stage: VideoStage) {
        writeVideoOrder(videosForStage(stage), stage: stage)
    }

    private func writeVideoOrder(_ ordered: [Video], stage: VideoStage) {
        for (i, video) in ordered.enumerated() {
            _ = db.execute("UPDATE videos SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, video.id])
        }
    }

    func addVideoComment(videoID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO video_comments (video_id, body, created_at) VALUES (?, ?, ?)",
            [videoID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    // MARK: - Thoughts

    func thoughtsForList(_ list: ThoughtList) -> [Thought] {
        thoughts
            .filter { $0.list == list }
            .sorted { $0.position < $1.position }
    }

    func thoughtByID(_ id: Int) -> Thought? {
        thoughts.first { $0.id == id }
    }

    func thought(_ t: Thought, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if t.title.lowercased().contains(q) { return true }
        if t.note.lowercased().contains(q) { return true }
        return false
    }

    func addThought(title: String, note: String = "", list: ThoughtList = .longTerm) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let position = thoughtsForList(list).count
        _ = db.execute(
            "INSERT INTO thoughts (title, note, list, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [trimmed, note, list.rawValue, position, now, now]
        )
        refresh()
    }

    func addThoughts(_ titles: [String], list: ThoughtList) {
        let parsed = titles
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !parsed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        var position = thoughtsForList(list).count
        for title in parsed {
            _ = db.execute(
                "INSERT INTO thoughts (title, note, list, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                [title, "", list.rawValue, position, now, now]
            )
            position += 1
        }
        refresh()
    }

    func updateThought(id: Int, title: String? = nil, note: String? = nil, list: ThoughtList? = nil) {
        guard let t = thoughtByID(id) else { return }
        let newList = list ?? t.list
        _ = db.execute(
            "UPDATE thoughts SET title = ?, note = ?, list = ?, updated_at = ? WHERE id = ?",
            [title ?? t.title, note ?? t.note, newList.rawValue, Date().timeIntervalSince1970, id]
        )
        if let list, list != t.list {
            reindexThoughtList(t.list)
            reindexThoughtList(list)
        }
        refresh()
    }

    func deleteThought(_ id: Int) {
        _ = db.execute("DELETE FROM thoughts WHERE id = ?", [id])
        refresh()
    }

    func moveThought(_ id: Int, to list: ThoughtList, at index: Int) {
        guard let t = thoughtByID(id) else { return }
        let fromList = t.list
        var target = thoughtsForList(list)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(t, at: clamped)
        writeThoughtOrder(target, list: list)
        if fromList != list {
            writeThoughtOrder(thoughtsForList(fromList).filter { $0.id != id }, list: fromList)
        }
        refresh()
    }

    func reindexThoughtList(_ list: ThoughtList) {
        writeThoughtOrder(thoughtsForList(list), list: list)
    }

    private func writeThoughtOrder(_ ordered: [Thought], list: ThoughtList) {
        for (i, thought) in ordered.enumerated() {
            _ = db.execute("UPDATE thoughts SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, thought.id])
        }
    }

    func randomActiveThought() -> Thought? {
        thoughts.isEmpty ? nil : thoughts.randomElement()
    }

    // MARK: - Wins

    func win(_ w: Win, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return w.text.lowercased().contains(query.lowercased())
    }

    func addWin(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO wins (text, bookmarked, created_at) VALUES (?, 0, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteWin(_ id: Int) {
        _ = db.execute("DELETE FROM wins WHERE id = ?", [id])
        refresh()
    }

    func toggleWinBookmark(_ id: Int) -> Bool {
        guard let w = wins.first(where: { $0.id == id }) else { return false }
        let newValue = w.bookmarked ? 0 : 1
        _ = db.execute("UPDATE wins SET bookmarked = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    // MARK: - Fails

    func fail(_ f: Fail, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return f.text.lowercased().contains(query.lowercased())
    }

    func addFail(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO fails (text, bookmarked, created_at) VALUES (?, 0, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteFail(_ id: Int) {
        _ = db.execute("DELETE FROM fails WHERE id = ?", [id])
        refresh()
    }

    func toggleFailBookmark(_ id: Int) -> Bool {
        guard let f = fails.first(where: { $0.id == id }) else { return false }
        let newValue = f.bookmarked ? 0 : 1
        _ = db.execute("UPDATE fails SET bookmarked = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    // MARK: - Interstitial Notes

    func interNote(_ n: InterNote, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return n.text.lowercased().contains(query.lowercased())
    }

    func addInterNote(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO interstitial_notes (text, created_at) VALUES (?, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteInterNote(_ id: Int) {
        _ = db.execute("DELETE FROM interstitial_notes WHERE id = ?", [id])
        refresh()
    }

    func toggleInterNoteBookmark(_ id: Int) {
        guard let note = interNotes.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE interstitial_notes SET bookmarked = ? WHERE id = ?", [note.bookmarked ? 0 : 1, id])
        refresh()
    }

    func updateInterNote(_ id: Int, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE interstitial_notes SET text = ? WHERE id = ?", [trimmed, id])
        refresh()
    }

    func moveInterNoteToTop(_ id: Int) {
        _ = db.execute("UPDATE interstitial_notes SET created_at = ? WHERE id = ?", [Date().timeIntervalSince1970, id])
        refresh()
    }

    // MARK: - Buck Track

    func buckActiveCount(_ q: String) -> Int {
        fetchBucksFiltered(q).filter { $0.status == .active }.count
    }

    func buck(_ b: Buck, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return b.title.lowercased().contains(q) || b.notes.lowercased().contains(q)
    }

    func addBuck(title: String, notes: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = (bucks.map(\.position).max() ?? 0) + 1
        _ = db.execute(
            "INSERT INTO bucks (title, status, notes, position, created_at, updated_at) VALUES (?, 'active', ?, ?, ?, ?)",
            [trimmed, notes, next, Date().timeIntervalSince1970, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func setBuckStatus(_ id: Int, _ status: BuckStatus) {
        _ = db.execute(
            "UPDATE bucks SET status = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateBuckNote(_ id: Int, notes: String) {
        _ = db.execute(
            "UPDATE bucks SET notes = ?, updated_at = ? WHERE id = ?",
            [notes, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteBuck(_ id: Int) {
        _ = db.execute("DELETE FROM bucks WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Focus Tracker

    var currentFocus: Focus? {
        focusSessions.first { $0.isActive }
    }

    func focus(_ f: Focus, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return f.text.lowercased().contains(q) || f.note.lowercased().contains(q)
    }

    func startFocus(text: String, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, currentFocus == nil else { return }
        _ = db.execute(
            "INSERT INTO focus (text, note, started_at, ended_at) VALUES (?, ?, ?, NULL)",
            [trimmed, note, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func endFocus() {
        guard let f = currentFocus else { return }
        _ = db.execute("UPDATE focus SET ended_at = ? WHERE id = ?", [Date().timeIntervalSince1970, f.id])
        refresh()
    }

    func updateFocusNote(_ id: Int, note: String) {
        _ = db.execute("UPDATE focus SET note = ? WHERE id = ?", [note, id])
        refresh()
    }

    func deleteFocus(_ id: Int) {
        _ = db.execute("DELETE FROM focus WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Parallel

    func parallelItem(_ p: ParallelItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.text.lowercased().contains(q) || p.note.lowercased().contains(q)
    }

    func addParallelItem(lane: Int, text: String, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO parallel (lane, text, note, created_at) VALUES (?, ?, ?, ?)",
            [lane, trimmed, note, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func moveParallelItem(_ id: Int, to lane: Int) {
        _ = db.execute("UPDATE parallel SET lane = ? WHERE id = ?", [lane, id])
        refresh()
    }

    func updateParallelNote(_ id: Int, note: String) {
        _ = db.execute("UPDATE parallel SET note = ? WHERE id = ?", [note, id])
        refresh()
    }

    func deleteParallelItem(_ id: Int) {
        _ = db.execute("DELETE FROM parallel WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Project Tracker

    func project(_ p: Project, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.name.lowercased().contains(q) || p.startNote.lowercased().contains(q) || p.stopNote.lowercased().contains(q)
    }

    func addProject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO projects (name, status, start_note, stop_note, created_at, updated_at) VALUES (?, 'inProgress', '', '', ?, ?)",
            [trimmed, Date().timeIntervalSince1970, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func startProject(_ id: Int) {
        let now = Date().timeIntervalSince1970
        _ = db.execute("UPDATE projects SET status = 'inProgress', updated_at = ? WHERE id != ? AND status = 'working'", [now, id])
        _ = db.execute("UPDATE projects SET status = 'working', updated_at = ? WHERE id = ?", [now, id])
        refresh()
    }

    func stopProject(_ id: Int) {
        _ = db.execute(
            "UPDATE projects SET status = 'inProgress', updated_at = ? WHERE id = ?",
            [Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setProjectStatus(_ id: Int, _ status: ProjectStatus) {
        _ = db.execute(
            "UPDATE projects SET status = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateProjectNotes(_ id: Int, startNote: String, stopNote: String) {
        _ = db.execute(
            "UPDATE projects SET start_note = ?, stop_note = ?, updated_at = ? WHERE id = ?",
            [startNote, stopNote, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteProject(_ id: Int) {
        _ = db.execute("DELETE FROM projects WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Long Term Projects

    private func loadLongTermProjects() -> [LongTermProject] {
        db.query("SELECT * FROM long_term_projects ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let statusRaw = row["status"] as? String,
                let status = LongTermProjectStatus(rawValue: statusRaw),
                let description = row["description"] as? String,
                let nextAction = row["next_action"] as? String,
                let progress = row["progress"] as? Int,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return LongTermProject(
                id: id,
                title: title,
                status: status,
                description: description,
                nextAction: nextAction,
                note: (row["note"] as? String) ?? "",
                progress: progress,
                startedAt: (row["started_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                targetAt: (row["target_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadLongTermMilestones() -> [LongTermMilestone] {
        db.query("SELECT * FROM long_term_milestones ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let projectID = row["project_id"] as? Int,
                let title = row["title"] as? String,
                let done = row["done"] as? Int,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return LongTermMilestone(
                id: id,
                projectId: projectID,
                title: title,
                done: done == 1,
                position: position,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadLongTermComments() -> [LongTermComment] {
        db.query("SELECT * FROM long_term_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let projectID = row["project_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return LongTermComment(
                id: id,
                projectId: projectID,
                parentId: row["parent_id"] as? Int,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func longTermProject(_ p: LongTermProject, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.title.lowercased().contains(q) || p.description.lowercased().contains(q) || p.nextAction.lowercased().contains(q)
    }

    func milestones(for projectID: Int) -> [LongTermMilestone] {
        longTermMilestones.filter { $0.projectId == projectID }.sorted { $0.position < $1.position }
    }

    @discardableResult
    func addLongTermProject(title: String, description: String, nextAction: String, status: LongTermProjectStatus, startedAt: Date?, targetAt: Date?) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO long_term_projects (title, status, description, next_action, progress, started_at, target_at, position, created_at, updated_at) VALUES (?, ?, ?, ?, 0, ?, ?, ?, ?, ?)",
            [trimmed, status.rawValue, description, nextAction, startedAt?.timeIntervalSince1970, targetAt?.timeIntervalSince1970, longTermProjects.count, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateLongTermProject(id: Int, title: String, description: String, nextAction: String, status: LongTermProjectStatus, progress: Int, startedAt: Date?, targetAt: Date?) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE long_term_projects SET title = ?, status = ?, description = ?, next_action = ?, progress = ?, started_at = ?, target_at = ?, updated_at = ? WHERE id = ?",
            [trimmed, status.rawValue, description, nextAction, min(max(progress, 0), 100), startedAt?.timeIntervalSince1970, targetAt?.timeIntervalSince1970, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setLongTermProjectProgress(id: Int, progress: Int) {
        let clamped = min(max(progress, 0), 100)
        _ = db.execute(
            "UPDATE long_term_projects SET progress = ?, updated_at = ? WHERE id = ?",
            [clamped, Date().timeIntervalSince1970, id]
        )
        if let index = longTermProjects.firstIndex(where: { $0.id == id }) {
            longTermProjects[index].progress = clamped
            longTermProjects[index].updatedAt = Date()
        }
    }

    func saveLongTermProjectNote(id: Int, note: String) {
        _ = db.execute(
            "UPDATE long_term_projects SET note = ?, updated_at = ? WHERE id = ?",
            [note, Date().timeIntervalSince1970, id]
        )
        if let index = longTermProjects.firstIndex(where: { $0.id == id }) {
            longTermProjects[index].note = note
            longTermProjects[index].updatedAt = Date()
        }
    }

    func longTermComments(for projectID: Int) -> [LongTermComment] {
        longTermComments.filter { $0.projectId == projectID }
    }

    func topLevelLongTermComments(for projectID: Int) -> [LongTermComment] {
        longTermComments(for: projectID).filter { !$0.isReply }.sorted { $0.createdAt < $1.createdAt }
    }

    func longTermReplies(to commentID: Int) -> [LongTermComment] {
        longTermComments.filter { $0.parentId == commentID }.sorted { $0.createdAt < $1.createdAt }
    }

    func addLongTermComment(projectID: Int, parentID: Int?, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO long_term_comments (project_id, parent_id, body, created_at) VALUES (?, ?, ?, ?)",
            [projectID, parentID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteLongTermComment(_ id: Int) {
        _ = db.execute("DELETE FROM long_term_comments WHERE id = ?", [id])
        _ = db.execute("DELETE FROM long_term_comments WHERE parent_id = ?", [id])
        refresh()
    }

    func moveLongTermProject(id: Int, direction: Int) {
        guard let index = longTermProjects.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < longTermProjects.count else { return }
        let other = longTermProjects[target]
        _ = db.execute("UPDATE long_term_projects SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE long_term_projects SET position = ?, updated_at = ? WHERE id = ?", [longTermProjects[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteLongTermProject(_ id: Int) {
        _ = db.execute("DELETE FROM long_term_projects WHERE id = ?", [id])
        _ = db.execute("DELETE FROM long_term_milestones WHERE project_id = ?", [id])
        _ = db.execute("DELETE FROM long_term_comments WHERE project_id = ?", [id])
        refresh()
    }

    @discardableResult
    func addLongTermMilestone(projectID: Int, title: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let count = milestones(for: projectID).count
        _ = db.execute(
            "INSERT INTO long_term_milestones (project_id, title, done, position, created_at) VALUES (?, ?, 0, ?, ?)",
            [projectID, trimmed, count, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func toggleLongTermMilestone(id: Int) {
        guard let milestone = longTermMilestones.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE long_term_milestones SET done = ? WHERE id = ?", [milestone.done ? 0 : 1, id])
        refresh()
    }

    func moveLongTermMilestone(id: Int, projectID: Int, direction: Int) {
        let list = milestones(for: projectID)
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE long_term_milestones SET position = ? WHERE id = ?", [other.position, id])
        _ = db.execute("UPDATE long_term_milestones SET position = ? WHERE id = ?", [list[index].position, other.id])
        refresh()
    }

    func deleteLongTermMilestone(_ id: Int) {
        _ = db.execute("DELETE FROM long_term_milestones WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Deep Work

    func deepWork(_ s: DeepWorkSession, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return query.lowercased().contains("deep") || query.lowercased().contains("work") || String(s.minutes).contains(query.lowercased())
    }

    var deepWorkMinutesToday: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        return deepWork.filter { $0.startedAt >= start }.reduce(0) { $0 + $1.minutes }
    }

    func completeDeepWork(minutes: Int) {
        completeDeepWork(minutes: minutes, note: deepWorkSessionNote)
    }

    func completeDeepWork(minutes: Int, note: String) {
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO deepwork_sessions (minutes, started_at, ended_at, completed, note) VALUES (?, ?, ?, 1, ?)",
            [minutes, now - Double(minutes) * 60, now, note]
        )
        deepWorkSessionNote = ""
        UserDefaults.standard.set("", forKey: "deepWorkSessionNote")
        refresh()
        addWin(text: "Completed a \(minutes)-minute deep work block")
    }

    func deleteDeepWork(_ id: Int) {
        _ = db.execute("DELETE FROM deepwork_sessions WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Schedule

    func scheduleEntry(day: Int, slot: Int) -> ScheduleEntry? {
        schedule.first { $0.day == day && $0.slot == slot }
    }

    func setScheduleTask(day: Int, slot: Int, task: String) {
        let trimmed = task.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date().timeIntervalSince1970
        if trimmed.isEmpty {
            _ = db.execute("DELETE FROM schedule WHERE day = ? AND slot = ?", [day, slot])
        } else if scheduleEntry(day: day, slot: slot) != nil {
            _ = db.execute("UPDATE schedule SET task = ?, updated_at = ? WHERE day = ? AND slot = ?", [trimmed, now, day, slot])
        } else {
            _ = db.execute("INSERT INTO schedule (day, slot, task, updated_at) VALUES (?, ?, ?, ?)", [day, slot, trimmed, now])
        }
        refresh()
    }

    func clearScheduleSlot(day: Int, slot: Int) {
        _ = db.execute("DELETE FROM schedule WHERE day = ? AND slot = ?", [day, slot])
        refresh()
    }

    func schedule(_ e: ScheduleEntry, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return e.task.lowercased().contains(query.lowercased())
    }

    // MARK: - Holding Hand

    func holdingItem(_ h: HoldingItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return h.text.lowercased().contains(query.lowercased())
    }

    func addHolding(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO holding (text, bookmarked, done, created_at) VALUES (?, 0, 0, ?)",
            [trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteHolding(_ id: Int) {
        _ = db.execute("DELETE FROM holding WHERE id = ?", [id])
        refresh()
    }

    func toggleHoldingBookmark(_ id: Int) -> Bool {
        guard let h = holding.first(where: { $0.id == id }) else { return false }
        let newValue = h.bookmarked ? 0 : 1
        _ = db.execute("UPDATE holding SET bookmarked = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    func toggleHoldingDone(_ id: Int) -> Bool {
        guard let h = holding.first(where: { $0.id == id }) else { return false }
        let newValue = h.done ? 0 : 1
        _ = db.execute("UPDATE holding SET done = ? WHERE id = ?", [newValue, id])
        refresh()
        return newValue == 1
    }

    // MARK: - Urgent

    func urgentItem(_ u: UrgentItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return u.text.lowercased().contains(q) || u.note.lowercased().contains(q)
    }

    func urgentItems(for urgency: Urgency) -> [UrgentItem] {
        urgent
            .filter { $0.urgency == urgency }
            .sorted { $0.position < $1.position }
    }

    func addUrgent(text: String, urgency: Urgency, note: String = "") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let position = urgentItems(for: urgency).count
        _ = db.execute(
            "INSERT INTO urgent (urgency, text, note, position, done, created_at, updated_at) VALUES (?, ?, ?, ?, 0, ?, ?)",
            [urgency.rawValue, trimmed, note, position, now, now]
        )
        refresh()
    }

    func moveUrgent(_ id: Int, to urgency: Urgency, at index: Int) {
        guard let item = urgent.first(where: { $0.id == id }) else { return }
        let from = item.urgency
        var target = urgentItems(for: urgency)
        target.removeAll { $0.id == id }
        let clamped = max(0, min(index, target.count))
        target.insert(item, at: clamped)
        writeUrgentOrder(target, urgency: urgency)
        if from != urgency {
            writeUrgentOrder(urgentItems(for: from).filter { $0.id != id }, urgency: from)
        }
        refresh()
    }

    func updateUrgent(id: Int, text: String? = nil, note: String? = nil, urgency: Urgency? = nil) {
        guard let item = urgent.first(where: { $0.id == id }) else { return }
        let newUrgency = urgency ?? item.urgency
        _ = db.execute(
            "UPDATE urgent SET text = ?, note = ?, urgency = ?, updated_at = ? WHERE id = ?",
            [text ?? item.text, note ?? item.note, newUrgency.rawValue, Date().timeIntervalSince1970, id]
        )
        if let urgency, urgency != item.urgency {
            writeUrgentOrder(urgentItems(for: item.urgency).filter { $0.id != id }, urgency: item.urgency)
            writeUrgentOrder(urgentItems(for: urgency), urgency: urgency)
        }
        refresh()
    }

    func toggleUrgentDone(_ id: Int) -> Bool {
        guard let item = urgent.first(where: { $0.id == id }) else { return false }
        let newValue = item.done ? 0 : 1
        _ = db.execute("UPDATE urgent SET done = ?, updated_at = ? WHERE id = ?", [newValue, Date().timeIntervalSince1970, id])
        refresh()
        return newValue == 1
    }

    func deleteUrgent(_ id: Int) {
        guard let item = urgent.first(where: { $0.id == id }) else { return }
        _ = db.execute("DELETE FROM urgent WHERE id = ?", [id])
        writeUrgentOrder(urgentItems(for: item.urgency).filter { $0.id != id }, urgency: item.urgency)
        refresh()
    }

    private func writeUrgentOrder(_ ordered: [UrgentItem], urgency: Urgency) {
        for (i, item) in ordered.enumerated() {
            _ = db.execute("UPDATE urgent SET position = ?, updated_at = ? WHERE id = ?", [i, Date().timeIntervalSince1970, item.id])
        }
    }

    // MARK: - Mini Mind Map

    func mindMapNode(_ n: MindMapNode, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return n.text.lowercased().contains(query.lowercased())
    }

    func mindMap(_ m: MindMap, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return m.title.lowercased().contains(query.lowercased())
    }

    func nodesForMap(_ mapID: Int) -> [MindMapNode] {
        mindMapNodes.filter { $0.mapId == mapID }
    }

    func rootNode(for mapID: Int) -> MindMapNode? {
        nodesForMap(mapID).first { $0.isRoot }
    }

    func children(of nodeID: Int, in mapID: Int) -> [MindMapNode] {
        nodesForMap(mapID).filter { $0.parentId == nodeID }
    }

    func addMindMap(title: String = "Untitled Map") -> Int {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Untitled Map" : trimmed
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO mindmaps (title, created_at, updated_at) VALUES (?, ?, ?)",
            [name, now, now]
        )
        let mapID = db.lastInsertID()
        _ = db.execute(
            "INSERT INTO mindmap_nodes (map_id, parent_id, text, color, x, y, created_at, updated_at) VALUES (?, NULL, 'Main idea', 'blue', ?, ?, ?, ?)",
            [mapID, Double(900), Double(600), now, now]
        )
        refresh()
        return mapID
    }

    func renameMindMap(id: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE mindmaps SET title = ?, updated_at = ? WHERE id = ?",
            [trimmed, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteMindMap(_ id: Int) {
        _ = db.execute("DELETE FROM mindmap_nodes WHERE map_id = ?", [id])
        _ = db.execute("DELETE FROM mindmaps WHERE id = ?", [id])
        refresh()
    }

    func addMindMapNode(mapID: Int, parentID: Int, text: String = "") {
        let now = Date().timeIntervalSince1970
        guard let parent = mindMapNodes.first(where: { $0.id == parentID }) else { return }
        let children = children(of: parentID, in: mapID)
        let offset = Double(children.count) * 150.0 - Double(children.count) * 30.0
        let x = parent.x + 230
        let y = parent.y + offset - Double(children.count) * 60.0 + 60.0
        _ = db.execute(
            "INSERT INTO mindmap_nodes (map_id, parent_id, text, color, x, y, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [mapID, parentID, text, parent.color, x, y, now, now]
        )
        refresh()
    }

    func updateMindMapNodeText(_ id: Int, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = db.execute(
            "UPDATE mindmap_nodes SET text = ?, updated_at = ? WHERE id = ?",
            [trimmed, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateMindMapNodeColor(_ id: Int, color: String) {
        _ = db.execute(
            "UPDATE mindmap_nodes SET color = ?, updated_at = ? WHERE id = ?",
            [color, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveMindMapNode(_ id: Int, x: Double, y: Double) {
        _ = db.execute(
            "UPDATE mindmap_nodes SET x = ?, y = ?, updated_at = ? WHERE id = ?",
            [x, y, Date().timeIntervalSince1970, id]
        )
        if let idx = mindMapNodes.firstIndex(where: { $0.id == id }) {
            let n = mindMapNodes[idx]
            mindMapNodes[idx] = MindMapNode(
                id: n.id, mapId: n.mapId, parentId: n.parentId, text: n.text, color: n.color,
                x: x, y: y, createdAt: n.createdAt, updatedAt: Date()
            )
        }
    }

    func deleteMindMapNode(_ id: Int) {
        var toDelete: [Int] = [id]
        var queue = [id]
        while !queue.isEmpty {
            let current = queue.removeFirst()
            for child in mindMapNodes where child.parentId == current {
                toDelete.append(child.id)
                queue.append(child.id)
            }
        }
        for nodeID in toDelete {
            _ = db.execute("DELETE FROM mindmap_nodes WHERE id = ?", [nodeID])
        }
        refresh()
    }

    // MARK: - Blog posts

    func blogPost(_ p: BlogPost, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        if p.title.lowercased().contains(q) { return true }
        if p.body.lowercased().contains(q) { return true }
        return p.tags.lowercased().contains(q)
    }

    func addBlogPost(title: String, body: String = "", tags: String = "", status: BlogPostStatus = .draft) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO blog_posts (title, body, status, tags, created_at, updated_at, published_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [trimmed, body, status.rawValue, tags, now, now, status == .published ? now : nil]
        )
        refresh()
    }

    func updateBlogPost(id: Int, title: String? = nil, body: String? = nil, tags: String? = nil, status: BlogPostStatus? = nil) {
        guard let post = blogPosts.first(where: { $0.id == id }) else { return }
        let newStatus = status ?? post.status
        _ = db.execute(
            "UPDATE blog_posts SET title = ?, body = ?, status = ?, tags = ?, updated_at = ? WHERE id = ?",
            [title ?? post.title, body ?? post.body, newStatus.rawValue, tags ?? post.tags, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setBlogPostStatus(_ id: Int, _ status: BlogPostStatus) {
        guard let post = blogPosts.first(where: { $0.id == id }) else { return }
        let now = Date().timeIntervalSince1970
        if status == .published && post.status != .published {
            _ = db.execute(
                "UPDATE blog_posts SET status = ?, published_at = ?, updated_at = ? WHERE id = ?",
                [status.rawValue, now, now, id]
            )
        } else if status == .draft {
            _ = db.execute(
                "UPDATE blog_posts SET status = ?, published_at = NULL, updated_at = ? WHERE id = ?",
                [status.rawValue, now, id]
            )
        }
        refresh()
    }

    func deleteBlogPost(_ id: Int) {
        _ = db.execute("DELETE FROM blog_posts WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Mini Slack

    private func seedSlackIfNeeded() {
        let settings = db.allSettings
        guard settings["slackSeeded"] != "true" else { return }
        insertSlackChannel(name: "general", color: "blue")
        db.setSetting("slackSeeded", "true")
        refresh()
    }

    func slackChannel(_ c: SlackChannel, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return c.name.lowercased().contains(query.lowercased())
    }

    func slackMessage(_ m: SlackMessage, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return m.text.lowercased().contains(q) || m.author.lowercased().contains(q)
    }

    func messages(in channelID: Int) -> [SlackMessage] {
        slackMessages.filter { $0.channelId == channelID }
    }

    func addSlackChannel(name: String, color: String = "blue") -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        _ = db.execute(
            "INSERT INTO slack_channels (name, color, created_at) VALUES (?, ?, ?)",
            [trimmed, color, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func renameSlackChannel(id: Int, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE slack_channels SET name = ? WHERE id = ?", [trimmed, id])
        refresh()
    }

    func deleteSlackChannel(_ id: Int) {
        _ = db.execute("DELETE FROM slack_messages WHERE channel_id = ?", [id])
        _ = db.execute("DELETE FROM slack_channels WHERE id = ?", [id])
        refresh()
    }

    func sendSlackMessage(channelID: Int, author: String = "Me", text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO slack_messages (channel_id, author, text, created_at) VALUES (?, ?, ?, ?)",
            [channelID, author, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteSlackMessage(_ id: Int) {
        _ = db.execute("DELETE FROM slack_messages WHERE id = ?", [id])
        refresh()
    }

    private func insertSlackChannel(name: String, color: String) {
        _ = db.execute(
            "INSERT INTO slack_channels (name, color, created_at) VALUES (?, ?, ?)",
            [name, color, Date().timeIntervalSince1970]
        )
    }

    // MARK: - Calendar

    func calendarEvent(_ e: CalendarEvent, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return e.title.lowercased().contains(q) || e.note.lowercased().contains(q)
    }

    func events(on day: String) -> [CalendarEvent] {
        calendarEvents
            .filter { $0.day == day }
            .sorted {
                if $0.time != $1.time { return $0.time < $1.time }
                return $0.createdAt < $1.createdAt
            }
    }

    func eventsInMonth(of date: Date) -> [CalendarEvent] {
        let prefix = String(dayString(date).prefix(7))
        return calendarEvents.filter { $0.day.hasPrefix(prefix) }
    }

    func addCalendarEvent(title: String, day: String, time: String = "", color: String = "blue", note: String = "", reminder: Int = 0) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO calendar_events (title, day, time, color, note, reminder, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [trimmed, day, time, color, note, reminder, now, now]
        )
        refresh()
        syncCalendarReminders()
    }

    func updateCalendarEvent(id: Int, title: String? = nil, time: String? = nil, color: String? = nil, note: String? = nil, reminder: Int? = nil) {
        guard let event = calendarEvents.first(where: { $0.id == id }) else { return }
        _ = db.execute(
            "UPDATE calendar_events SET title = ?, time = ?, color = ?, note = ?, reminder = ?, updated_at = ? WHERE id = ?",
            [title ?? event.title, time ?? event.time, color ?? event.color, note ?? event.note, reminder ?? event.reminder, Date().timeIntervalSince1970, id]
        )
        refresh()
        syncCalendarReminders()
    }

    func deleteCalendarEvent(_ id: Int) {
        _ = db.execute("DELETE FROM calendar_events WHERE id = ?", [id])
        refresh()
        syncCalendarReminders()
    }

    // MARK: Calendar notifications

    func requestNotificationPermission(completion: @escaping @Sendable (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func sendTestCalendarNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Comment Tracker"
        content.body = "This is a test notification from your Calendar."
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "calendar-test-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func syncCalendarReminders() {
        let center = UNUserNotificationCenter.current()
        let identifiers = calendarEvents.map { "calendar-\($0.id)" }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
        center.getNotificationSettings { settings in
            let authorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            guard authorized else { return }
            Task { @MainActor in
                let currentCenter = UNUserNotificationCenter.current()
                let events = self.calendarEvents.filter { $0.reminder > 0 }
                for event in events {
                    guard let fireDate = self.reminderFireDate(for: event), fireDate > Date() else { continue }
                    let content = UNMutableNotificationContent()
                    content.title = event.title
                    content.body = self.reminderBody(for: event)
                    content.sound = .default
                    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    currentCenter.add(UNNotificationRequest(identifier: "calendar-\(event.id)", content: content, trigger: trigger))
                }
            }
        }
    }

    private func reminderFireDate(for event: CalendarEvent) -> Date? {
        guard let base = eventTimeDate(for: event) else { return nil }
        return base.addingTimeInterval(-TimeInterval(event.reminder) * 60)
    }

    private func eventTimeDate(for event: CalendarEvent) -> Date? {
        guard let base = dateFromDay(event.day) else { return nil }
        let trimmed = event.time.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: base)
        }
        let cal = Calendar.current
        let dayComps = cal.dateComponents([.year, .month, .day], from: base)
        let formats = ["HH:mm", "H:mm", "h:mm a", "h:mma", "h:mm"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let parsed = formatter.date(from: trimmed) {
                var comps = cal.dateComponents([.hour, .minute], from: parsed)
                comps.year = dayComps.year
                comps.month = dayComps.month
                comps.day = dayComps.day
                return cal.date(from: comps)
            }
        }
        return nil
    }

    private func reminderBody(for event: CalendarEvent) -> String {
        var parts: [String] = []
        if let date = dateFromDay(event.day) {
            parts.append(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
        }
        if !event.time.isEmpty {
            parts.append(event.time)
        }
        if !event.note.isEmpty {
            parts.append(event.note)
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Backup & Restore

    @discardableResult
    func backup(to url: URL) -> Bool {
        db.backup(to: url)
    }

    @discardableResult
    func restore(from url: URL) -> Bool {
        let ok = db.restore(from: url)
        if ok { load() }
        return ok
    }

    // MARK: - Links

    func link(_ l: LinkItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return l.label.lowercased().contains(q) || l.url.lowercased().contains(q)
    }

    func addLink(label: String, url: String) {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let position = links.count
        _ = db.execute(
            "INSERT INTO links (label, url, position, created_at) VALUES (?, ?, ?, ?)",
            [label, trimmed, position, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func updateLink(id: Int, label: String? = nil, url: String? = nil) {
        guard let l = links.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE links SET label = ?, url = ? WHERE id = ?", [label ?? l.label, url ?? l.url, id])
        refresh()
    }

    func deleteLink(_ id: Int) {
        _ = db.execute("DELETE FROM links WHERE id = ?", [id])
        refresh()
    }

    func moveLink(_ id: Int, to newIndex: Int) {
        guard let link = links.first(where: { $0.id == id }) else { return }
        var ordered = links
        guard let fromIndex = ordered.firstIndex(where: { $0.id == id }) else { return }
        ordered.remove(at: fromIndex)
        ordered.insert(link, at: max(0, min(newIndex, ordered.count)))
        for (i, l) in ordered.enumerated() {
            _ = db.execute("UPDATE links SET position = ? WHERE id = ?", [i, l.id])
        }
        refresh()
    }

    // MARK: - 313 Cards

    func card(_ c: WordCard, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if c.word.lowercased().contains(q) { return true }
        if c.groupName.lowercased().contains(q) { return true }
        if c.wordsText.lowercased().contains(q) { return true }
        return false
    }

    func addCard(word: String, group: String = "", words: [String] = [], link: String = "") {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        let slot = (cards.map(\.slot).max() ?? 0) + 1
        let wordsText = words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "|")
        _ = db.execute(
            "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [slot, trimmed, group.trimmingCharacters(in: .whitespacesAndNewlines), wordsText, link, now, now]
        )
        refresh()
    }

    func updateCard(id: Int, word: String? = nil, group: String? = nil, words: [String]? = nil, link: String? = nil) {
        guard let c = cards.first(where: { $0.id == id }) else { return }
        let wordsText = (words ?? c.words).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: "|")
        _ = db.execute(
            "UPDATE wordcards SET word = ?, group_name = ?, words = ?, link = ?, updated_at = ? WHERE id = ?",
            [word ?? c.word, group ?? c.groupName, wordsText, link ?? c.link, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteCard(_ id: Int) {
        _ = db.execute("DELETE FROM wordcards WHERE id = ?", [id])
        refresh()
    }

    func addAllEmptyCards(target: Int = 313) -> Int {
        let nextSlot = (cards.map(\.slot).max() ?? 0) + 1
        let toAdd = max(0, target - (nextSlot - 1))
        if toAdd == 0 { return 0 }
        let now = Date().timeIntervalSince1970
        for i in 0..<toAdd {
            _ = db.execute(
                "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [nextSlot + i, "", "Empty", "", "", now, now]
            )
        }
        refresh()
        return toAdd
    }

    func resetDeck(target: Int = 313) {
        _ = db.execute("DELETE FROM wordcards")
        let now = Date().timeIntervalSince1970
        for i in 0..<max(0, target) {
            _ = db.execute(
                "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [i + 1, "", "Empty", "", "", now, now]
            )
        }
        refresh()
    }

    var totalEmptySlots: Int {
        cards.filter { $0.word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var cardGroups: [String] {
        var seen: [String] = []
        for c in cards {
            let g = c.groupName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !g.isEmpty && !seen.contains(g) { seen.append(g) }
        }
        return seen
    }

    func exportCards() -> String? {
        struct CardDTO: Codable {
            let slot: Int
            let word: String
            var group: String
            var words: [String]
            var link: String
        }
        let dtos = cards.sorted(by: { $0.slot < $1.slot }).map { CardDTO(slot: $0.slot, word: $0.word, group: $0.groupName, words: $0.words, link: $0.link) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(dtos) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importCards(fromJSON text: String) -> Int {
        guard let data = text.data(using: .utf8) else { return 0 }
        struct CardDTO: Decodable {
            let word: String
            var slot: Int?
            var group: String?
            var words: [String]?
            var link: String?
        }
        guard let dtos = try? JSONDecoder().decode([CardDTO].self, from: data) else { return 0 }
        var added = 0
        let now = Date().timeIntervalSince1970
        var nextSlot = (cards.map(\.slot).max() ?? 0) + 1
        for d in dtos {
            let w = d.word.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !w.isEmpty else { continue }
            let slot = d.slot ?? nextSlot
            if slot >= nextSlot { nextSlot = slot + 1 }
            _ = db.execute(
                "INSERT INTO wordcards (slot, word, group_name, words, link, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                [slot, w, d.group ?? "", (d.words ?? []).joined(separator: "|"), d.link ?? "", now, now]
            )
            added += 1
        }
        if added > 0 { refresh() }
        return added
    }

    // MARK: - Stacks (push / pop)

    func uncategorizedStack() -> Stack? {
        stacks.first { $0.name == "Uncategorized" } ?? stacks.first
    }

    func items(in stackID: Int) -> [StackItem] {
        stackItems.filter { $0.stackId == stackID }.sorted { $0.position < $1.position }
    }

    func stackItem(_ item: StackItem, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if item.title.lowercased().contains(q) { return true }
        if item.description.lowercased().contains(q) { return true }
        return false
    }

    func stackComments(for itemID: Int) -> [StackComment] {
        stackComments.filter { $0.itemId == itemID }.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func addStack(name: String, color: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO stacks (name, color, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            [trimmed, color, stacks.count, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateStack(id: Int, name: String, color: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE stacks SET name = ?, color = ?, updated_at = ? WHERE id = ?",
            [trimmed, color, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteStack(_ id: Int) {
        _ = db.execute("DELETE FROM stacks WHERE id = ?", [id])
        let orphanIDs = stackItems.filter { $0.stackId == id }.map(\.id)
        _ = db.execute("DELETE FROM stack_items WHERE stack_id = ?", [id])
        for itemID in orphanIDs {
            _ = db.execute("DELETE FROM stack_comments WHERE item_id = ?", [itemID])
        }
        refresh()
    }

    func moveStack(id: Int, direction: Int) {
        guard let index = stacks.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < stacks.count else { return }
        let other = stacks[target]
        _ = db.execute("UPDATE stacks SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE stacks SET position = ?, updated_at = ? WHERE id = ?", [stacks[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    @discardableResult
    func pushStackItem(stackID: Int, title: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let count = items(in: stackID).count
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO stack_items (stack_id, title, description, links, position, created_at, updated_at) VALUES (?, ?, '', '', ?, ?, ?)",
            [stackID, trimmed, count, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateStackItem(id: Int, title: String, description: String, links: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE stack_items SET title = ?, description = ?, links = ?, updated_at = ? WHERE id = ?",
            [trimmed, description, links, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteStackItem(_ id: Int) {
        _ = db.execute("DELETE FROM stack_items WHERE id = ?", [id])
        _ = db.execute("DELETE FROM stack_comments WHERE item_id = ?", [id])
        refresh()
    }

    @discardableResult
    func popStackItem(id: Int) -> Int? {
        guard let item = stackItems.first(where: { $0.id == id }) else { return nil }
        guard let target = uncategorizedStack() else { return nil }
        _ = db.execute(
            "UPDATE stack_items SET stack_id = ?, position = ?, updated_at = ? WHERE id = ?",
            [target.id, items(in: target.id).count, Date().timeIntervalSince1970, id]
        )
        refresh()
        return target.id
    }

    func popTopItem(from stackID: Int) -> Int? {
        guard let top = items(in: stackID).first else { return nil }
        return popStackItem(id: top.id)
    }

    func addStackComment(itemID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO stack_comments (item_id, body, created_at) VALUES (?, ?, ?)",
            [itemID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteStackComment(_ id: Int) {
        _ = db.execute("DELETE FROM stack_comments WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Pomodoro

    var focusSessionsToday: Int {
        let dayStart = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return pomodoros.filter { $0.mode == .focus && $0.endedAt != nil && $0.startedAt.timeIntervalSince1970 >= dayStart }.count
    }

    @discardableResult
    func addPomodoro(mode: PomodoroMode, startedAt: Date) -> Int {
        _ = db.execute("INSERT INTO pomodoro_sessions (mode, started_at) VALUES (?, ?)", [mode.rawValue, startedAt.timeIntervalSince1970])
        return db.lastInsertID()
    }

    func endPomodoro(id: Int) {
        _ = db.execute("UPDATE pomodoro_sessions SET ended_at = ? WHERE id = ?", [Date().timeIntervalSince1970, id])
        refresh()
    }

    // MARK: - Persistent timer engine (pomodoro + deep work)

    var pomodoroTotal: Int { pomodoroMode.minutes * 60 }
    var pomodoroProgress: Double { 1 - Double(pomodoroRemaining) / Double(max(1, pomodoroTotal)) }
    var pomodoroTimeText: String {
        String(format: "%02d:%02d", pomodoroRemaining / 60, pomodoroRemaining % 60)
    }
    var pomodoroColor: Color {
        switch pomodoroMode {
        case .focus: return .red
        case .short: return .green
        case .long: return .blue
        }
    }

    var deepWorkProgress: Double {
        guard deepWorkSelectedMinutes > 0 else { return 0 }
        return Double(deepWorkSecondsLeft) / Double(deepWorkSelectedMinutes * 60)
    }

    func setPomodoroMode(_ mode: PomodoroMode) {
        pomodoroMode = mode
        resetPomodoro()
    }

    func togglePomodoro() {
        pomodoroRunning ? pausePomodoro() : startPomodoro()
    }

    func startPomodoro() {
        requestNotificationPermission()
        pomodoroStartedAt = Date()
        pomodoroEndTime = pomodoroStartedAt.addingTimeInterval(TimeInterval(pomodoroRemaining))
        pomodoroRunning = true
        pomodoroSessionID = addPomodoro(mode: pomodoroMode, startedAt: pomodoroStartedAt)
    }

    func pausePomodoro() {
        pomodoroRunning = false
    }

    func resetPomodoro() {
        pomodoroRunning = false
        pomodoroEndTime = nil
        pomodoroRemaining = pomodoroTotal
        pomodoroSessionID = nil
    }

    func startDeepWorkTimer() {
        requestNotificationPermission()
        if deepWorkSecondsLeft == 0 {
            deepWorkSecondsLeft = deepWorkSelectedMinutes * 60
        }
        deepWorkRunning = true
        deepWorkRunningSince = Date()
    }

    func pauseDeepWorkTimer() {
        deepWorkRunning = false
    }

    func resetDeepWorkTimer() {
        deepWorkRunning = false
        deepWorkSecondsLeft = 0
        deepWorkSelectedMinutes = 60
    }

    private func tickTimers() {
        if pomodoroRunning, let end = pomodoroEndTime {
            let secs = Int(end.timeIntervalSinceNow)
            if secs <= 0 {
                completePomodoro()
            } else {
                pomodoroRemaining = secs
            }
        }
        if deepWorkRunning {
            let elapsed = Int(Date().timeIntervalSince(deepWorkRunningSince))
            let newValue = max(0, deepWorkSecondsLeft - elapsed)
            deepWorkSecondsLeft = newValue
            if newValue <= 0 {
                completeDeepWorkTimer()
            }
        }
        if let player = audioPlayer {
            audioPlaybackTime = player.currentTime
            if isPlaying && !player.isPlaying {
                handlePlaybackFinished()
            }
        }
        if isRecordingAudio, let start = recordingStartedAt {
            recordingAudioTime = Date().timeIntervalSince(start)
        }
    }

    private func completePomodoro() {
        if let sessionID = pomodoroSessionID {
            endPomodoro(id: sessionID)
        }
        refresh()
        playPomodoroSound()
        pomodoroRunning = false
        pomodoroEndTime = nil
        let finishedMode = pomodoroMode
        if finishedMode == .focus {
            sendTimerNotification(title: "Focus complete!", body: "Nice work — time for a \(PomodoroMode.short.minutes)-minute break.")
            pomodoroMode = .short
        } else {
            sendTimerNotification(title: "Break over", body: "Ready for another focus block?")
            pomodoroMode = .focus
        }
        pomodoroRemaining = pomodoroTotal
        pomodoroSessionID = nil
    }

    private func completeDeepWorkTimer() {
        deepWorkRunning = false
        playDeepWorkSound()
        let finished = deepWorkSelectedMinutes
        completeDeepWork(minutes: finished)
        sendTimerNotification(title: "Deep work complete!", body: "You finished a \(finished)-minute deep work block.")
        deepWorkSecondsLeft = 0
    }

    func playPomodoroSound() {
        if let sound = NSSound(named: "Glass") {
            sound.play()
            return
        }
        if let sound = NSSound(named: "Tink") {
            sound.play()
            return
        }
        NSSound.beep()
    }

    func sendTimerNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "timer-\(UUID().uuidString)", content: content, trigger: nil)
        )
    }

    // MARK: - Sprints

    func sprint(_ s: Sprint, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if s.name.lowercased().contains(q) { return true }
        if s.notes.lowercased().contains(q) { return true }
        return false
    }

    func story(_ s: Story, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        return s.title.lowercased().contains(q)
    }

    func addSprint(name: String, startAt: Date?, endAt: Date?, notes: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO sprints (name, start_at, end_at, notes, done, created_at, updated_at) VALUES (?, ?, ?, ?, 0, ?, ?)",
            [trimmed, startAt?.timeIntervalSince1970, endAt?.timeIntervalSince1970, notes, now, now]
        )
        refresh()
    }

    func updateSprint(id: Int, name: String? = nil, startAt: Date? = nil, endAt: Date? = nil, notes: String? = nil, done: Bool? = nil) {
        guard let s = sprints.first(where: { $0.id == id }) else { return }
        let newDone = done ?? s.done
        _ = db.execute(
            "UPDATE sprints SET name = ?, start_at = ?, end_at = ?, notes = ?, done = ?, updated_at = ? WHERE id = ?",
            [name ?? s.name, startAt?.timeIntervalSince1970, endAt?.timeIntervalSince1970, notes ?? s.notes, newDone ? 1 : 0, Date().timeIntervalSince1970, id]
        )
        if let done, done && !s.done {
            addWin(text: "Sprint done: \(name ?? s.name)")
        } else {
            refresh()
        }
    }

    func deleteSprint(_ id: Int) {
        let storyIDs = stories.filter { $0.sprintId == id }.map { $0.id }
        for sid in storyIDs {
            _ = db.execute("DELETE FROM story_tasks WHERE story_id = ?", [sid])
        }
        _ = db.execute("DELETE FROM stories WHERE sprint_id = ?", [id])
        _ = db.execute("DELETE FROM sprints WHERE id = ?", [id])
        refresh()
    }

    func storiesForSprint(_ sprintId: Int) -> [Story] {
        stories.filter { $0.sprintId == sprintId }.sorted { $0.updatedAt < $1.updatedAt }
    }

    func addStory(sprintId: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO stories (sprint_id, title, created_at, updated_at) VALUES (?, ?, ?, ?)", [sprintId, trimmed, now, now])
        refresh()
    }

    func updateStory(id: Int, title: String? = nil, sprintId: Int? = nil) {
        guard let st = stories.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE stories SET title = ?, sprint_id = ?, updated_at = ? WHERE id = ?",
                       [title ?? st.title, sprintId ?? st.sprintId, Date().timeIntervalSince1970, id])
        refresh()
    }

    func deleteStory(_ id: Int) {
        _ = db.execute("DELETE FROM story_tasks WHERE story_id = ?", [id])
        _ = db.execute("DELETE FROM stories WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Tasks

    func tasksForStory(_ storyId: Int) -> [StoryTask] {
        storyTasks.filter { $0.storyId == storyId }.sorted { $0.updatedAt < $1.updatedAt }
    }

    func tasksForSprint(_ sprintId: Int) -> [StoryTask] {
        let sid = Set(storiesForSprint(sprintId).map { $0.id })
        return storyTasks.filter { sid.contains($0.storyId) }
    }

    func addTask(storyId: Int, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO story_tasks (story_id, title, done, created_at, updated_at) VALUES (?, ?, 0, ?, ?)", [storyId, trimmed, now, now])
        refresh()
    }

    func updateTask(id: Int, title: String? = nil, done: Bool? = nil) {
        guard let t = storyTasks.first(where: { $0.id == id }) else { return }
        let newDone = done ?? t.done
        _ = db.execute("UPDATE story_tasks SET title = ?, done = ?, updated_at = ? WHERE id = ?",
                       [title ?? t.title, newDone ? 1 : 0, Date().timeIntervalSince1970, id])
        if let done, done && !t.done {
            addWin(text: "Task done: \(title ?? t.title)")
        } else {
            refresh()
        }
    }

    func deleteTask(_ id: Int) {
        _ = db.execute("DELETE FROM story_tasks WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Trackers

    var enabledTrackers: [Tracker] {
        trackers.filter { $0.enabled }
    }

    func trackerByID(_ id: Int) -> Tracker? {
        trackers.first { $0.id == id }
    }

    var trackerCategories: [String] {
        var seen: [String] = []
        let order = ["Namaz", "Quran", "Zikr", "Dua", "Fasting", "Masjid", "Family", "Parents", "Relatives", "Parenting", "Friends", "Health", "Business", "Custom"]
        for cat in order where enabledTrackers.contains(where: { $0.category == cat }) {
            seen.append(cat)
        }
        for t in enabledTrackers where !seen.contains(t.category) {
            seen.append(t.category)
        }
        return seen
    }

    func trackersForCategory(_ category: String) -> [Tracker] {
        enabledTrackers
            .filter { $0.category == category }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func tracker(_ t: Tracker, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        return t.name.lowercased().contains(q)
            || t.category.lowercased().contains(q)
            || t.scheduleNote.lowercased().contains(q)
    }

    // MARK: Entries

    func entry(for trackerID: Int, on day: String) -> TrackerEntry? {
        trackerEntries.first { $0.trackerId == trackerID && $0.day == day }
    }

    func count(for trackerID: Int, on day: String) -> Int {
        entry(for: trackerID, on: day)?.count ?? 0
    }

    func note(for trackerID: Int, on day: String) -> String {
        entry(for: trackerID, on: day)?.note ?? ""
    }

    func isDone(trackerID: Int, on day: String) -> Bool {
        count(for: trackerID, on: day) > 0
    }

    func toggle(_ trackerID: Int, on day: String) {
        let current = count(for: trackerID, on: day)
        upsertEntry(trackerID: trackerID, day: day, count: current > 0 ? 0 : 1, note: nil)
    }

    func setCount(_ trackerID: Int, on day: String, _ value: Int) {
        upsertEntry(trackerID: trackerID, day: day, count: max(0, value), note: nil)
    }

    func setNote(_ trackerID: Int, on day: String, _ note: String) {
        upsertEntry(trackerID: trackerID, day: day, count: nil, note: note)
    }

    private func upsertEntry(trackerID: Int, day: String, count: Int?, note: String?) {
        let existing = entry(for: trackerID, on: day)
        let c = count ?? existing?.count ?? 0
        let n = note ?? existing?.note ?? ""
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO tracker_entries (tracker_id, day, count, note, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(tracker_id, day) DO UPDATE SET count = excluded.count, note = excluded.note, updated_at = excluded.updated_at",
            [trackerID, day, c, n, now, now]
        )
        refresh()
    }

    func entries(for trackerID: Int, inMonthOf date: Date) -> [TrackerEntry] {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        guard let monthStart = cal.date(from: comps),
              let monthEnd = cal.date(byAdding: DateComponents(month: 1), to: monthStart) else { return [] }
        let start = dayString(monthStart)
        let end = dayString(monthEnd)
        return trackerEntries.filter { $0.trackerId == trackerID && $0.day >= start && $0.day < end }
    }

    func daysDone(for trackerID: Int, inMonthOf date: Date) -> Set<String> {
        Set(entries(for: trackerID, inMonthOf: date).filter { $0.count > 0 }.map { $0.day })
    }

    func monthDoneCount(for trackerID: Int, inMonthOf date: Date) -> Int {
        daysDone(for: trackerID, inMonthOf: date).count
    }

    func streak(for trackerID: Int) -> Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: Date())
        let today = day
        if !isDone(trackerID: trackerID, on: dayString(today)) {
            guard let y = cal.date(byAdding: .day, value: -1, to: today),
                  isDone(trackerID: trackerID, on: dayString(y)) else { return 0 }
            day = y
        }
        var count = 0
        while isDone(trackerID: trackerID, on: dayString(day)) {
            count += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    // MARK: CRUD

    func addTracker(name: String, category: String, icon: String, colorName: String, isCounter: Bool, target: Int, scheduleNote: String) {
        let now = Date().timeIntervalSince1970
        let maxOrder = (trackers.filter { $0.category == category }.map { $0.sortOrder }.max() ?? -1) + 1
        _ = db.execute(
            "INSERT INTO trackers (name, icon, color, category, is_counter, target, schedule_note, is_preset, enabled, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1, ?, ?, ?)",
            [name, icon, colorName, category, isCounter ? 1 : 0, max(1, target), scheduleNote, maxOrder, now, now]
        )
        refresh()
    }

    func updateTracker(id: Int, enabled: Bool? = nil, target: Int? = nil) {
        guard let t = trackerByID(id) else { return }
        _ = db.execute(
            "UPDATE trackers SET enabled = ?, target = ?, updated_at = ? WHERE id = ?",
            [enabled ?? t.enabled ? 1 : 0, target ?? t.target, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteTracker(_ id: Int) {
        _ = db.execute("DELETE FROM tracker_entries WHERE tracker_id = ?", [id])
        _ = db.execute("DELETE FROM trackers WHERE id = ?", [id])
        refresh()
    }

    func seedPresetsIfNeeded() {
        let settings = db.allSettings
        guard settings["presetsSeeded"] != "true" else { return }
        insertPresets()
        db.setSetting("presetsSeeded", "true")
        refresh()
    }

    func reseedMissingPresets() {
        let existingNames = Set(trackers.map { $0.name })
        let missing = TrackerPreset.all.filter { !existingNames.contains($0.name) }
        guard !missing.isEmpty else { return }
        insertPresets(missing)
        refresh()
    }

    private func insertPresets(_ presets: [TrackerPreset] = TrackerPreset.all) {
        let now = Date().timeIntervalSince1970
        for (i, p) in presets.enumerated() {
            _ = db.execute(
                "INSERT INTO trackers (name, icon, color, category, is_counter, target, schedule_note, is_preset, enabled, sort_order, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1, ?, ?, ?)",
                [p.name, p.icon, p.color, p.category, p.isCounter ? 1 : 0, p.target, p.scheduleNote, i, now, now]
            )
        }
    }

    // MARK: - Derived data

    var todayStart: Date {
        Calendar.current.startOfDay(for: Date())
    }

    var todayComments: [Comment] {
        let start = todayStart
        return comments.filter { $0.createdAt >= start }
    }

    var todayCount: Int { todayComments.count }

    var todayByPlatform: [Platform: Int] {
        var out: [Platform: Int] = [:]
        for c in todayComments {
            out[c.platform, default: 0] += 1
        }
        return out
    }

    var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1, Double(todayCount) / Double(goal))
    }

    var subGoalProgress: Double {
        guard subGoal > 0 else { return 0 }
        return min(1, Double(todayCount) / Double(subGoal))
    }

    var remainingSubGoal: Int {
        max(0, subGoal - todayCount)
    }

    var remainingCount: Int {
        max(0, goal - todayCount)
    }

    var currentMilestone: Milestone? {
        Milestone.reached(by: progress)
    }

    var nextMilestone: Milestone? {
        Milestone.next(after: progress)
    }

    var minutesElapsedToday: Double {
        max(1, Date().timeIntervalSince(todayStart) / 60)
    }

    var pacePerHour: Double {
        let hours = minutesElapsedToday / 60
        return Double(todayCount) / hours
    }

    var estimatedFinish: TimeInterval? {
        guard pacePerHour > 0, remainingCount > 0 else { return nil }
        return TimeInterval(remainingCount) / pacePerHour * 3600
    }

    var weeklyCounts: [DailyCount] {
        var counts: [Date: Int] = [:]
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -6, to: todayStart)!
        for c in comments {
            let day = cal.startOfDay(for: c.createdAt)
            if day >= start {
                counts[day, default: 0] += 1
            }
        }
        return (0...6).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            return DailyCount(date: day, count: counts[day] ?? 0)
        }
    }

    var totalCount: Int { comments.count }

    var totalSessions: Int { sessions.count }

    var totalTime: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    // MARK: - Private loading

    private func loadComments() -> [Comment] {
        db.query("SELECT * FROM comments ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let pRaw = row["platform"] as? String,
                let p = Platform(rawValue: pRaw),
                let ts = row["created_at"] as? Double
            else { return nil }
            return Comment(
                id: id,
                platform: p,
                body: row["body"] as? String,
                url: row["url"] as? String,
                createdAt: Date(timeIntervalSince1970: ts),
                sessionId: row["session_id"] as? Int
            )
        }
    }

    private func loadSessions() -> [Session] {
        let rows = db.query("""
        SELECT s.*, (SELECT COUNT(*) FROM comments c WHERE c.session_id = s.id) AS comments_added
        FROM sessions s ORDER BY s.started_at DESC
        """)
        return rows.compactMap { row in
            guard
                let id = row["id"] as? Int,
                let start = row["started_at"] as? Double
            else { return nil }
            return Session(
                id: id,
                startedAt: Date(timeIntervalSince1970: start),
                endedAt: (row["ended_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                goal: row["goal"] as? Int ?? 0,
                commentsAdded: row["comments_added"] as? Int ?? 0
            )
        }
    }

    private func loadPeople() -> [Person] {
        db.query("SELECT * FROM people ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let stageRaw = row["stage"] as? String,
                let stage = PersonStage(rawValue: stageRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Person(
                id: id,
                name: name,
                brief: row["brief"] as? String ?? "",
                description: row["description"] as? String ?? "",
                stage: stage,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadPersonLinks() -> [PersonLink] {
        db.query("SELECT * FROM people_links").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let personID = row["person_id"] as? Int,
                let url = row["url"] as? String,
                let kindRaw = row["kind"] as? String,
                let kind = PersonLinkKind(rawValue: kindRaw)
            else { return nil }
            return PersonLink(
                id: id,
                personId: personID,
                label: row["label"] as? String ?? "",
                url: url,
                kind: kind
            )
        }
    }

    private func loadPersonComments() -> [PersonComment] {
        db.query("SELECT * FROM people_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let personID = row["person_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return PersonComment(
                id: id,
                personId: personID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadLinks() -> [LinkItem] {
        db.query("SELECT * FROM links ORDER BY position ASC, created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let url = row["url"] as? String, let created = row["created_at"] as? Double else { return nil }
            return LinkItem(id: id, label: row["label"] as? String ?? "", url: url, position: row["position"] as? Int ?? 0, createdAt: Date(timeIntervalSince1970: created))
        }
    }

    private func loadCards() -> [WordCard] {
        db.query("SELECT * FROM wordcards ORDER BY slot ASC, created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let word = row["word"] as? String, let created = row["created_at"] as? Double else { return nil }
            return WordCard(
                id: id,
                slot: row["slot"] as? Int ?? 0,
                word: word,
                groupName: row["group_name"] as? String ?? "",
                words: (row["words"] as? String ?? "").split(separator: "|").map(String.init),
                link: row["link"] as? String ?? "",
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadStacks() -> [Stack] {
        db.query("SELECT * FROM stacks ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let color = row["color"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Stack(
                id: id,
                name: name,
                color: color,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadStackItems() -> [StackItem] {
        db.query("SELECT * FROM stack_items ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let stackID = row["stack_id"] as? Int,
                let title = row["title"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return StackItem(
                id: id,
                stackId: stackID,
                title: title,
                description: row["description"] as? String ?? "",
                links: row["links"] as? String ?? "",
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadStackComments() -> [StackComment] {
        db.query("SELECT * FROM stack_comments ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let itemID = row["item_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return StackComment(
                id: id,
                itemId: itemID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadPomodoros() -> [PomodoroSession] {        db.query("SELECT * FROM pomodoro_sessions ORDER BY started_at DESC").compactMap { row in
            guard let id = row["id"] as? Int, let modeRaw = row["mode"] as? String, let mode = PomodoroMode(rawValue: modeRaw), let created = row["started_at"] as? Double else { return nil }
            return PomodoroSession(id: id, mode: mode, startedAt: Date(timeIntervalSince1970: created), endedAt: (row["ended_at"] as? Double).map { Date(timeIntervalSince1970: $0) })
        }
    }

    private func loadSprints() -> [Sprint] {
        db.query("SELECT * FROM sprints ORDER BY created_at DESC").compactMap { row in
            guard let id = row["id"] as? Int, let name = row["name"] as? String, let created = row["created_at"] as? Double else { return nil }
            return Sprint(
                id: id,
                name: name,
                startAt: (row["start_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                endAt: (row["end_at"] as? Double).map { Date(timeIntervalSince1970: $0) },
                notes: row["notes"] as? String ?? "",
                done: (row["done"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadStories() -> [Story] {
        db.query("SELECT * FROM stories ORDER BY created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let sprintID = row["sprint_id"] as? Int, let title = row["title"] as? String, let created = row["created_at"] as? Double else { return nil }
            return Story(id: id, sprintId: sprintID, title: title, createdAt: Date(timeIntervalSince1970: created), updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created))
        }
    }

    private func loadStoryTasks() -> [StoryTask] {
        db.query("SELECT * FROM story_tasks ORDER BY created_at ASC").compactMap { row in
            guard let id = row["id"] as? Int, let storyID = row["story_id"] as? Int, let title = row["title"] as? String, let created = row["created_at"] as? Double else { return nil }
            return StoryTask(id: id, storyId: storyID, title: title, done: (row["done"] as? Int ?? 0) == 1, createdAt: Date(timeIntervalSince1970: created), updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created))
        }
    }

    private func loadWins() -> [Win] {
        db.query("SELECT * FROM wins ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return Win(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadFails() -> [Fail] {
        db.query("SELECT * FROM fails ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return Fail(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadInterNotes() -> [InterNote] {
        db.query("SELECT * FROM interstitial_notes ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return InterNote(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func fetchBucksFiltered(_ q: String) -> [Buck] {
        let query = q.trimmingCharacters(in: .whitespacesAndNewlines)
        let all = loadBucks()
        guard !query.isEmpty else { return all }
        return all.filter { buck($0, matches: query) }
    }

    private func loadBucks() -> [Buck] {
        let order = "CASE status WHEN 'active' THEN 0 WHEN 'paused' THEN 1 ELSE 2 END"
        return db.query("SELECT * FROM bucks ORDER BY \(order), updated_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let statusRaw = row["status"] as? String,
                let notes = row["notes"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            let status = BuckStatus(rawValue: statusRaw) ?? .active
            return Buck(
                id: id,
                title: title,
                status: status,
                notes: notes,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadFocus() -> [Focus] {
        db.query("SELECT * FROM focus ORDER BY started_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let note = row["note"] as? String,
                let started = row["started_at"] as? Double
            else { return nil }
            let ended = (row["ended_at"] as? Double).map { Date(timeIntervalSince1970: $0) }
            return Focus(id: id, text: text, note: note, startedAt: Date(timeIntervalSince1970: started), endedAt: ended)
        }
    }

    private func loadParallel() -> [ParallelItem] {
        db.query("SELECT * FROM parallel ORDER BY lane ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let lane = row["lane"] as? Int,
                let text = row["text"] as? String,
                let note = row["note"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return ParallelItem(id: id, lane: lane, text: text, note: note, createdAt: Date(timeIntervalSince1970: created))
        }
    }

    private func loadProjects() -> [Project] {
        let order = "CASE status WHEN 'working' THEN 0 WHEN 'inProgress' THEN 1 ELSE 2 END, updated_at DESC"
        return db.query("SELECT * FROM projects ORDER BY \(order)").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let statusRaw = row["status"] as? String,
                let startNote = row["start_note"] as? String,
                let stopNote = row["stop_note"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Project(
                id: id,
                name: name,
                status: ProjectStatus(rawValue: statusRaw) ?? .inProgress,
                startNote: startNote,
                stopNote: stopNote,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadDeepWork() -> [DeepWorkSession] {
        db.query("SELECT * FROM deepwork_sessions ORDER BY started_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let minutes = row["minutes"] as? Int,
                let started = row["started_at"] as? Double,
                let ended = row["ended_at"] as? Double,
                let completed = row["completed"] as? Int
            else { return nil }
            return DeepWorkSession(
                id: id,
                minutes: minutes,
                startedAt: Date(timeIntervalSince1970: started),
                endedAt: Date(timeIntervalSince1970: ended),
                completed: completed == 1,
                note: row["note"] as? String ?? ""
            )
        }
    }

    private func loadDeepWorkTasks() -> [DeepWorkTask] {
        db.query("SELECT * FROM deepwork_tasks ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let done = row["done"] as? Int,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return DeepWorkTask(
                id: id,
                text: text,
                done: done == 1,
                position: position,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    @discardableResult
    func addDeepWorkTask(text: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        _ = db.execute(
            "INSERT INTO deepwork_tasks (text, done, position, created_at) VALUES (?, 0, ?, ?)",
            [trimmed, deepWorkTasks.count, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func toggleDeepWorkTask(id: Int) {
        guard let task = deepWorkTasks.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE deepwork_tasks SET done = ? WHERE id = ?", [task.done ? 0 : 1, id])
        refresh()
    }

    func deleteDeepWorkTask(_ id: Int) {
        _ = db.execute("DELETE FROM deepwork_tasks WHERE id = ?", [id])
        refresh()
    }

    func moveDeepWorkTask(id: Int, direction: Int) {
        let sorted = deepWorkTasks.sorted { $0.position < $1.position }
        guard let index = sorted.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < sorted.count else { return }
        let other = sorted[target]
        _ = db.execute("UPDATE deepwork_tasks SET position = ? WHERE id = ?", [other.position, id])
        _ = db.execute("UPDATE deepwork_tasks SET position = ? WHERE id = ?", [sorted[index].position, other.id])
        refresh()
    }

    // MARK: Deep work sound preferences

    func loadDeepWorkPrefs() {
        deepWorkSoundPreset = UserDefaults.standard.string(forKey: "deepWorkSoundPreset") ?? "Glass"
        deepWorkSoundCustomPath = UserDefaults.standard.string(forKey: "deepWorkSoundCustomPath")
        let duration = UserDefaults.standard.integer(forKey: "deepWorkSoundDuration")
        deepWorkSoundDuration = duration > 0 ? duration : 5
        deepWorkSessionNote = UserDefaults.standard.string(forKey: "deepWorkSessionNote") ?? ""
    }

    func setDeepWorkSoundPreset(_ preset: String) {
        deepWorkSoundPreset = preset
        UserDefaults.standard.set(preset, forKey: "deepWorkSoundPreset")
    }

    func setDeepWorkSoundCustomPath(_ path: String?) {
        deepWorkSoundCustomPath = path
        UserDefaults.standard.set(path ?? "", forKey: "deepWorkSoundCustomPath")
    }

    func setDeepWorkSoundDuration(_ duration: Int) {
        deepWorkSoundDuration = duration
        UserDefaults.standard.set(duration, forKey: "deepWorkSoundDuration")
    }

    func setDeepWorkSessionNote(_ note: String) {
        deepWorkSessionNote = note
        UserDefaults.standard.set(note, forKey: "deepWorkSessionNote")
    }

    func playDeepWorkSound() {
        stopDeepWorkSound()
        guard let sound = makeDeepWorkSound() else {
            NSSound.beep()
            return
        }
        sound.loops = true
        sound.play()
        deepWorkSound = sound
        let seconds = max(1, deepWorkSoundDuration)
        deepWorkSoundStopTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds) * 1_000_000_000)
            self?.stopDeepWorkSound()
        }
    }

    func stopDeepWorkSound() {
        deepWorkSoundStopTask?.cancel()
        deepWorkSoundStopTask = nil
        deepWorkSound?.stop()
        deepWorkSound = nil
    }

    private func makeDeepWorkSound() -> NSSound? {
        if deepWorkSoundPreset == "custom", let path = deepWorkSoundCustomPath, !path.isEmpty {
            let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : URL(string: path)
            if let url {
                return NSSound(contentsOf: url, byReference: true)
            }
        }
        return NSSound(named: NSSound.Name(deepWorkSoundPreset)) ?? NSSound(named: "Glass")
    }

    private func loadSchedule() -> [ScheduleEntry] {
        db.query("SELECT * FROM schedule").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let day = row["day"] as? Int,
                let slot = row["slot"] as? Int,
                let task = row["task"] as? String,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return ScheduleEntry(id: id, day: day, slot: slot, task: task, updatedAt: Date(timeIntervalSince1970: updated))
        }
    }

    private func loadHolding() -> [HoldingItem] {
        db.query("SELECT * FROM holding ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return HoldingItem(
                id: id,
                text: text,
                bookmarked: (row["bookmarked"] as? Int ?? 0) == 1,
                done: (row["done"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadUrgent() -> [UrgentItem] {
        db.query("SELECT * FROM urgent ORDER BY urgency ASC, position ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let urgencyRaw = row["urgency"] as? Int,
                let urgency = Urgency(rawValue: urgencyRaw),
                let text = row["text"] as? String,
                let note = row["note"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return UrgentItem(
                id: id,
                urgency: urgency,
                text: text,
                note: note,
                position: position,
                done: (row["done"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadMindMaps() -> [MindMap] {
        db.query("SELECT * FROM mindmaps ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return MindMap(
                id: id,
                title: title,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadMindMapNodes() -> [MindMapNode] {
        db.query("SELECT * FROM mindmap_nodes").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let mapID = row["map_id"] as? Int,
                let text = row["text"] as? String,
                let x = row["x"] as? Double,
                let y = row["y"] as? Double,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return MindMapNode(
                id: id,
                mapId: mapID,
                parentId: row["parent_id"] as? Int,
                text: text,
                color: row["color"] as? String ?? "blue",
                x: x,
                y: y,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadBlogPosts() -> [BlogPost] {
        db.query("SELECT * FROM blog_posts ORDER BY updated_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let body = row["body"] as? String,
                let statusRaw = row["status"] as? String,
                let status = BlogPostStatus(rawValue: statusRaw),
                let tags = row["tags"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return BlogPost(
                id: id,
                title: title,
                body: body,
                status: status,
                tags: tags,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated),
                publishedAt: (row["published_at"] as? Double).map { Date(timeIntervalSince1970: $0) }
            )
        }
    }

    private func loadSlackChannels() -> [SlackChannel] {
        db.query("SELECT * FROM slack_channels ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return SlackChannel(
                id: id,
                name: name,
                color: row["color"] as? String ?? "blue",
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadSlackMessages() -> [SlackMessage] {
        db.query("SELECT * FROM slack_messages ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let channelID = row["channel_id"] as? Int,
                let author = row["author"] as? String,
                let text = row["text"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return SlackMessage(
                id: id,
                channelId: channelID,
                author: author,
                text: text,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadCalendarEvents() -> [CalendarEvent] {
        db.query("SELECT * FROM calendar_events ORDER BY day ASC, time ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let day = row["day"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return CalendarEvent(
                id: id,
                title: title,
                day: day,
                time: row["time"] as? String ?? "",
                color: row["color"] as? String ?? "blue",
                note: row["note"] as? String ?? "",
                reminder: row["reminder"] as? Int ?? 0,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func seedYearCardsIfNeeded() {
        let count = (db.query("SELECT COUNT(*) AS c FROM year_cards").first?["c"] as? Int) ?? 0
        guard count == 0 else { return }
        for slot in 1...12 {
            _ = db.execute(
                "INSERT INTO year_cards (slot, word, created_at, updated_at) VALUES (?, ?, ?, ?)",
                [slot, "", Date().timeIntervalSince1970, Date().timeIntervalSince1970]
            )
        }
        refresh()
    }

    private func loadYearCards() -> [YearCard] {
        db.query("SELECT * FROM year_cards ORDER BY slot ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let slot = row["slot"] as? Int,
                let word = row["word"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return YearCard(
                id: id,
                slot: slot,
                word: word,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func yearCard(_ c: YearCard, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return c.word.lowercased().contains(q) || c.monthName.lowercased().contains(q)
    }

    func updateYearCard(id: Int, word: String) {
        _ = db.execute(
            "UPDATE year_cards SET word = ?, updated_at = ? WHERE id = ?",
            [word, Date().timeIntervalSince1970, id]
        )
        if let index = yearCards.firstIndex(where: { $0.id == id }) {
            yearCards[index].word = word
            yearCards[index].updatedAt = Date()
        }
    }

    func resetYearCards() {
        _ = db.execute("DELETE FROM year_cards")
        for slot in 1...12 {
            _ = db.execute(
                "INSERT INTO year_cards (slot, word, created_at, updated_at) VALUES (?, ?, ?, ?)",
                [slot, "", Date().timeIntervalSince1970, Date().timeIntervalSince1970]
            )
        }
        refresh()
    }

    private func seedWeekCardsIfNeeded() {
        let count = (db.query("SELECT COUNT(*) AS c FROM week_cards").first?["c"] as? Int) ?? 0
        guard count == 0 else { return }
        for slot in 1...52 {
            _ = db.execute(
                "INSERT INTO week_cards (slot, title, note, created_at, updated_at) VALUES (?, '', '', ?, ?)",
                [slot, Date().timeIntervalSince1970, Date().timeIntervalSince1970]
            )
        }
        refresh()
    }

    private func loadWeekCards() -> [WeekCard] {
        db.query("SELECT * FROM week_cards ORDER BY slot ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let slot = row["slot"] as? Int,
                let title = row["title"] as? String,
                let note = row["note"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return WeekCard(
                id: id,
                slot: slot,
                title: title,
                note: note,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func weekCard(_ c: WeekCard, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return c.title.lowercased().contains(q)
            || c.note.lowercased().contains(q)
            || c.monthName.lowercased().contains(q)
            || "\(c.slot)".contains(q)
            || c.dateRangeText.lowercased().contains(q)
    }

    func updateWeekCard(id: Int, title: String, note: String) {
        _ = db.execute(
            "UPDATE week_cards SET title = ?, note = ?, updated_at = ? WHERE id = ?",
            [title, note, Date().timeIntervalSince1970, id]
        )
        if let index = weekCards.firstIndex(where: { $0.id == id }) {
            weekCards[index].title = title
            weekCards[index].note = note
            weekCards[index].updatedAt = Date()
        }
    }

    func exportWeeks() -> String? {
        struct WeekDTO: Codable {
            let slot: Int
            let title: String
            let note: String
        }
        let dtos = weekCards.sorted(by: { $0.slot < $1.slot }).map { WeekDTO(slot: $0.slot, title: $0.title, note: $0.note) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(dtos) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func importWeeks(fromJSON text: String) -> Int {
        guard let data = text.data(using: .utf8) else { return 0 }
        struct WeekDTO: Decodable {
            let slot: Int
            var title: String?
            var note: String?
        }
        guard let dtos = try? JSONDecoder().decode([WeekDTO].self, from: data) else { return 0 }
        let now = Date().timeIntervalSince1970
        var updated = 0
        for d in dtos {
            let slot = d.slot
            guard slot >= 1, slot <= 52 else { continue }
            if let existing = weekCards.first(where: { $0.slot == slot }) {
                let title = d.title ?? existing.title
                let note = d.note ?? existing.note
                _ = db.execute(
                    "UPDATE week_cards SET title = ?, note = ?, updated_at = ? WHERE id = ?",
                    [title, note, now, existing.id]
                )
                updated += 1
            }
        }
        if updated > 0 { refresh() }
        return updated
    }

    func resetWeekCards() {
        _ = db.execute("DELETE FROM week_cards")
        for slot in 1...52 {
            _ = db.execute(
                "INSERT INTO week_cards (slot, title, note, created_at, updated_at) VALUES (?, '', '', ?, ?)",
                [slot, Date().timeIntervalSince1970, Date().timeIntervalSince1970]
            )
        }
        refresh()
    }

    // MARK: - Audio notes

    var audioDirectoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("CommentTracker/AudioNotes", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func loadAudioNotes() -> [AudioNote] {
        db.query("SELECT * FROM audio_notes ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let filename = row["filename"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return AudioNote(
                id: id,
                title: title,
                notes: row["notes"] as? String ?? "",
                filename: filename,
                duration: row["duration"] as? Double ?? 0,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func audioNote(_ n: AudioNote, matches query: String) -> Bool {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if n.title.lowercased().contains(q) { return true }
        return n.notes.lowercased().contains(q)
    }

    func addAudioNote(title: String, notes: String = "", filename: String, duration: Double) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO audio_notes (title, notes, filename, duration, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [trimmed.isEmpty ? "Untitled note" : trimmed, notes, filename, duration, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateAudioNote(id: Int, title: String, notes: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE audio_notes SET title = ?, notes = ?, updated_at = ? WHERE id = ?",
            [trimmed, notes, Date().timeIntervalSince1970, id]
        )
        if let index = audioNotes.firstIndex(where: { $0.id == id }) {
            audioNotes[index].title = trimmed
            audioNotes[index].notes = notes
            audioNotes[index].updatedAt = Date()
        }
    }

    func deleteAudioNote(_ id: Int) {
        guard let note = audioNotes.first(where: { $0.id == id }) else { return }
        if nowPlayingAudioNoteID == id {
            stopAudioNotePlayback()
        }
        let file = audioDirectoryURL.appendingPathComponent(note.filename)
        try? FileManager.default.removeItem(at: file)
        _ = db.execute("DELETE FROM audio_notes WHERE id = ?", [id])
        _ = db.execute("DELETE FROM audio_note_comments WHERE note_id = ?", [id])
        refresh()
    }

    // MARK: Audio note playback & recording

    func playAudioNote(id: Int) {
        guard let note = audioNotes.first(where: { $0.id == id }) else { return }
        let file = audioDirectoryURL.appendingPathComponent(note.filename)
        guard let player = try? AVAudioPlayer(contentsOf: file) else { return }
        stopPlayback()
        audioPlayer = player
        audioPlayer?.play()
        nowPlayingAudioNoteID = id
        isPlaying = true
        audioPlaybackTime = 0
    }

    func toggleAudioNotePlayback(id: Int) {
        if nowPlayingAudioNoteID == id {
            togglePlayback()
        } else {
            playAudioNote(id: id)
        }
    }

    func stopAudioNotePlayback() {
        stopPlayback()
        nowPlayingAudioNoteID = nil
    }

    func startRecordingAudioNote() {
        stopPlayback()
        if audioRecorder?.isRecording == true {
            return
        }
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        let filename = "note-\(UUID().uuidString).m4a"
        let url = audioDirectoryURL.appendingPathComponent(filename)
        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return }
        recorder.record()
        audioRecorder = recorder
        currentRecordingFilename = filename
        recordingStartedAt = Date()
        recordingAudioTime = 0
        isRecordingAudio = true
    }

    @discardableResult
    func stopRecordingAudioNote() -> Int? {
        guard let recorder = audioRecorder else { return nil }
        let duration = recorder.currentTime
        recorder.stop()
        audioRecorder = nil
        isRecordingAudio = false
        recordingStartedAt = nil
        recordingAudioTime = 0
        let filename = currentRecordingFilename ?? ""
        currentRecordingFilename = nil
        let url = audioDirectoryURL.appendingPathComponent(filename)
        guard !filename.isEmpty else { return nil }
        var resolvedDuration = duration
        if resolvedDuration <= 0 {
            resolvedDuration = (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
        }
        if resolvedDuration <= 0.05 {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return addAudioNote(title: "Voice note — \(formatter.string(from: Date()))", notes: "", filename: filename, duration: resolvedDuration)
    }

    func cancelRecordingAudioNote() {
        guard audioRecorder?.isRecording == true else { return }
        audioRecorder?.stop()
        audioRecorder = nil
        isRecordingAudio = false
        recordingStartedAt = nil
        recordingAudioTime = 0
        if let filename = currentRecordingFilename {
            let url = audioDirectoryURL.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)
        }
        currentRecordingFilename = nil
    }

    // MARK: Audio note comments

    func audioNoteComments(for noteID: Int) -> [AudioNoteComment] {
        audioNoteComments
            .filter { $0.noteId == noteID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addAudioNoteComment(noteID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO audio_note_comments (note_id, body, created_at) VALUES (?, ?, ?)",
            [noteID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteAudioNoteComment(_ id: Int) {
        _ = db.execute("DELETE FROM audio_note_comments WHERE id = ?", [id])
        refresh()
    }

    private func loadAudioNoteComments() -> [AudioNoteComment] {
        db.query("SELECT * FROM audio_note_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let noteID = row["note_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return AudioNoteComment(
                id: id,
                noteId: noteID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func copyAudioNotePath(id: Int) {
        guard let note = audioNotes.first(where: { $0.id == id }) else { return }
        let path = audioDirectoryURL.appendingPathComponent(note.filename).path
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
    }

    // MARK: - Celebrations

    private func loadCelebrations() -> [Celebration] {
        db.query("SELECT * FROM celebrations ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let url = row["url"] as? String,
                let note = row["note"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Celebration(
                id: id,
                title: title,
                url: url,
                note: note,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadCelebrationComments() -> [CelebrationComment] {
        db.query("SELECT * FROM celebration_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let celebrationID = row["celebration_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return CelebrationComment(
                id: id,
                celebrationId: celebrationID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadCelebrationNotes() -> String {
        db.query("SELECT * FROM celebration_overview WHERE id = 1").first?["notes"] as? String ?? ""
    }

    func celebration(_ c: Celebration, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return c.title.lowercased().contains(q) || c.note.lowercased().contains(q)
    }

    @discardableResult
    func addCelebration(title: String, url: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO celebrations (title, url, note, position, created_at, updated_at) VALUES (?, ?, '', ?, ?, ?)",
            [trimmed, url, celebrations.count, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateCelebration(id: Int, title: String, url: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE celebrations SET title = ?, url = ?, updated_at = ? WHERE id = ?",
            [trimmed, url, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func updateCelebrationNote(id: Int, note: String) {
        _ = db.execute(
            "UPDATE celebrations SET note = ?, updated_at = ? WHERE id = ?",
            [note, Date().timeIntervalSince1970, id]
        )
        if let index = celebrations.firstIndex(where: { $0.id == id }) {
            celebrations[index].note = note
            celebrations[index].updatedAt = Date()
        }
    }

    func moveCelebration(id: Int, direction: Int) {
        guard let index = celebrations.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < celebrations.count else { return }
        let other = celebrations[target]
        _ = db.execute("UPDATE celebrations SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE celebrations SET position = ?, updated_at = ? WHERE id = ?", [celebrations[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteCelebration(_ id: Int) {
        _ = db.execute("DELETE FROM celebrations WHERE id = ?", [id])
        _ = db.execute("DELETE FROM celebration_comments WHERE celebration_id = ?", [id])
        refresh()
    }

    func celebrationComments(for celebrationID: Int) -> [CelebrationComment] {
        celebrationComments
            .filter { $0.celebrationId == celebrationID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addCelebrationComment(celebrationID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO celebration_comments (celebration_id, body, created_at) VALUES (?, ?, ?)",
            [celebrationID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteCelebrationComment(_ id: Int) {
        _ = db.execute("DELETE FROM celebration_comments WHERE id = ?", [id])
        refresh()
    }

    func saveCelebrationNotes(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if celebrationNotes == trimmed && !db.query("SELECT id FROM celebration_overview WHERE id = 1").isEmpty {
            return
        }
        if db.query("SELECT id FROM celebration_overview WHERE id = 1").isEmpty {
            _ = db.execute(
                "INSERT INTO celebration_overview (id, notes, updated_at) VALUES (1, ?, ?)",
                [trimmed, Date().timeIntervalSince1970]
            )
        } else {
            _ = db.execute(
                "UPDATE celebration_overview SET notes = ?, updated_at = ? WHERE id = 1",
                [trimmed, Date().timeIntervalSince1970]
            )
        }
        celebrationNotes = trimmed
    }

    // MARK: - Challenges

    private func loadChallenges() -> [Challenge] {
        db.query("SELECT * FROM challenges ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let body = row["body"] as? String,
                let statusRaw = row["status"] as? String,
                let status = ChallengeStatus(rawValue: statusRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Challenge(
                id: id,
                title: title,
                body: body,
                status: status,
                startDate: row["start_date"] as? String ?? "",
                endDate: row["end_date"] as? String ?? "",
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func challenge(_ c: Challenge, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return c.title.lowercased().contains(q) || c.body.lowercased().contains(q) || c.dateRangeText.lowercased().contains(q)
    }

    func challenges(for status: ChallengeStatus) -> [Challenge] {
        challenges.filter { $0.status == status }
    }

    @discardableResult
    func addChallenge(title: String, body: String, status: ChallengeStatus, startDate: String, endDate: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (challenges.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO challenges (title, body, status, start_date, end_date, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [trimmed, body, status.rawValue, startDate, endDate, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateChallenge(id: Int, title: String, body: String, startDate: String, endDate: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE challenges SET title = ?, body = ?, start_date = ?, end_date = ?, updated_at = ? WHERE id = ?",
            [trimmed, body, startDate, endDate, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setChallengeStatus(id: Int, status: ChallengeStatus) {
        _ = db.execute(
            "UPDATE challenges SET status = ?, position = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, (challenges.map(\.position).max() ?? 0) + 1, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteChallenge(_ id: Int) {
        _ = db.execute("DELETE FROM challenges WHERE id = ?", [id])
        _ = db.execute("DELETE FROM challenge_comments WHERE challenge_id = ?", [id])
        _ = db.execute("DELETE FROM challenge_prerequisites WHERE challenge_id = ? OR prerequisite_id = ?", [id, id])
        refresh()
    }

    private func loadChallengePrerequisiteLinks() -> [ChallengePrerequisiteLink] {
        db.query("SELECT * FROM challenge_prerequisites").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let challengeID = row["challenge_id"] as? Int,
                let prerequisiteID = row["prerequisite_id"] as? Int
            else { return nil }
            return ChallengePrerequisiteLink(id: id, challengeId: challengeID, prerequisiteId: prerequisiteID)
        }
    }

    func prerequisites(of challengeID: Int) -> [Challenge] {
        let ids = challengePrerequisiteLinks.filter { $0.challengeId == challengeID }.map(\.prerequisiteId)
        return challenges.filter { ids.contains($0.id) }
    }

    func prerequisiteIDs(of challengeID: Int) -> [Int] {
        challengePrerequisiteLinks.filter { $0.challengeId == challengeID }.map(\.prerequisiteId)
    }

    func incompletePrereqCount(of challengeID: Int) -> Int {
        prerequisites(of: challengeID).filter { $0.status != .completed }.count
    }

    @discardableResult
    func addPrerequisite(challengeID: Int, prerequisiteID: Int) -> Bool {
        guard challengeID != prerequisiteID else { return false }
        guard !challengePrerequisiteLinks.contains(where: { $0.challengeId == challengeID && $0.prerequisiteId == prerequisiteID }) else { return false }
        _ = db.execute(
            "INSERT INTO challenge_prerequisites (challenge_id, prerequisite_id) VALUES (?, ?)",
            [challengeID, prerequisiteID]
        )
        refresh()
        return true
    }

    func removePrerequisite(linkID: Int) {
        _ = db.execute("DELETE FROM challenge_prerequisites WHERE id = ?", [linkID])
        refresh()
    }

    // MARK: - Alarms

    var activeAlarms: [AlarmItem] {
        alarms.filter { !$0.fired && $0.fireAt > Date() }.sorted { $0.fireAt < $1.fireAt }
    }

    var firedAlarms: [AlarmItem] {
        alarms.filter { $0.fired || $0.fireAt <= Date() }.sorted { $0.fireAt > $1.fireAt }
    }

    private func loadAlarms() -> [AlarmItem] {
        db.query("SELECT * FROM alarms ORDER BY fire_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let label = row["label"] as? String,
                let fire = row["fire_at"] as? Double,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return AlarmItem(
                id: id,
                label: label,
                fireAt: Date(timeIntervalSince1970: fire),
                fired: (row["fired"] as? Int ?? 0) == 1,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func alarm(_ a: AlarmItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return a.label.lowercased().contains(q) || a.timeText.lowercased().contains(q)
    }

    @discardableResult
    func addAlarm(label: String, fireAt: Date) -> Int? {
        guard fireAt > Date() else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO alarms (label, fire_at, fired, created_at, updated_at) VALUES (?, ?, 0, ?, ?)",
            [label, fireAt.timeIntervalSince1970, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        scheduleAlarmNotification(id: id, label: label, fireAt: fireAt)
        return id
    }

    func updateAlarm(id: Int, label: String, fireAt: Date) {
        guard fireAt > Date() else { return }
        _ = db.execute(
            "UPDATE alarms SET label = ?, fire_at = ?, fired = 0, updated_at = ? WHERE id = ?",
            [label, fireAt.timeIntervalSince1970, Date().timeIntervalSince1970, id]
        )
        refresh()
        if let alarm = alarms.first(where: { $0.id == id }) {
            removeAlarmNotification(id: id)
            scheduleAlarmNotification(id: id, label: alarm.label, fireAt: alarm.fireAt)
        }
    }

    func deleteAlarm(_ id: Int) {
        removeAlarmNotification(id: id)
        _ = db.execute("DELETE FROM alarms WHERE id = ?", [id])
        refresh()
    }

    func snoozeAlarm(id: Int, minutes: Int = 5) {
        let newFire = Date().addingTimeInterval(TimeInterval(minutes * 60))
        updateAlarm(id: id, label: alarms.first { $0.id == id }?.label ?? "Alarm", fireAt: newFire)
    }

    private func scheduleAlarmNotification(id: Int, label: String, fireAt: Date) {
        requestNotificationPermission()
        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "Alarm" : label
        content.body = "⏰ \(alarmDescription(fireAt))"
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "alarm-\(id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func removeAlarmNotification(id: Int) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["alarm-\(id)"])
    }

    func syncAlarmNotifications() {
        for alarm in activeAlarms {
            removeAlarmNotification(id: alarm.id)
            scheduleAlarmNotification(id: alarm.id, label: alarm.label, fireAt: alarm.fireAt)
        }
    }

    // MARK: - Tools

    var sortedTools: [Tool] {
        tools.sorted { $0.position < $1.position }
    }

    private func loadTools() -> [Tool] {
        db.query("SELECT * FROM tools ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let note = row["note"] as? String,
                let link = row["link"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Tool(
                id: id,
                name: name,
                note: note,
                link: link,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func tool(_ t: Tool, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return t.name.lowercased().contains(q) || t.note.lowercased().contains(q) || t.link.lowercased().contains(q)
    }

    @discardableResult
    func addTool(name: String, note: String, link: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (tools.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO tools (name, note, link, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [trimmed, note, link, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateTool(id: Int, name: String, note: String, link: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE tools SET name = ?, note = ?, link = ?, updated_at = ? WHERE id = ?",
            [trimmed, note, link, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveTool(id: Int, direction: Int) {
        let list = sortedTools
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE tools SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE tools SET position = ?, updated_at = ? WHERE id = ?", [list[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteTool(_ id: Int) {
        _ = db.execute("DELETE FROM tools WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Old dreams

    var sortedDreams: [Dream] {
        dreams.sorted { $0.position < $1.position }
    }

    private func loadDreams() -> [Dream] {
        db.query("SELECT * FROM dreams ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let note = row["note"] as? String,
                let link = row["link"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Dream(
                id: id,
                title: title,
                note: note,
                link: link,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func dream(_ d: Dream, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return d.title.lowercased().contains(q) || d.note.lowercased().contains(q) || d.link.lowercased().contains(q)
    }

    @discardableResult
    func addDream(title: String, note: String, link: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (dreams.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO dreams (title, note, link, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [trimmed, note, link, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateDream(id: Int, title: String, note: String, link: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE dreams SET title = ?, note = ?, link = ?, updated_at = ? WHERE id = ?",
            [trimmed, note, link, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveDream(id: Int, direction: Int) {
        let list = sortedDreams
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE dreams SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE dreams SET position = ?, updated_at = ? WHERE id = ?", [list[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteDream(_ id: Int) {
        _ = db.execute("DELETE FROM dreams WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Feature requests

    private func loadFeatureRequests() -> [FeatureRequest] {
        db.query("SELECT * FROM feature_requests ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let app = row["app"] as? String,
                let title = row["title"] as? String,
                let body = row["body"] as? String,
                let statusRaw = row["status"] as? String,
                let status = FeatureRequestStatus(rawValue: statusRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return FeatureRequest(
                id: id,
                app: app,
                title: title,
                body: body,
                status: status,
                link: row["link"] as? String ?? "",
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func featureRequest(_ f: FeatureRequest, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return f.title.lowercased().contains(q) || f.body.lowercased().contains(q) || f.app.lowercased().contains(q) || f.link.lowercased().contains(q)
    }

    func featureRequests(for status: FeatureRequestStatus) -> [FeatureRequest] {
        featureRequests.filter { $0.status == status }.sorted { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    func addFeatureRequest(app: String, title: String, body: String, link: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (featureRequests.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO feature_requests (app, title, body, status, link, position, created_at, updated_at) VALUES (?, ?, ?, 'idea', ?, ?, ?, ?)",
            [app.trimmingCharacters(in: .whitespacesAndNewlines), trimmed, body, link, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateFeatureRequest(id: Int, app: String, title: String, body: String, link: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE feature_requests SET app = ?, title = ?, body = ?, link = ?, updated_at = ? WHERE id = ?",
            [app.trimmingCharacters(in: .whitespacesAndNewlines), trimmed, body, link, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setFeatureRequestStatus(id: Int, status: FeatureRequestStatus) {
        _ = db.execute(
            "UPDATE feature_requests SET status = ?, position = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, (featureRequests.map(\.position).max() ?? 0) + 1, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteFeatureRequest(_ id: Int) {
        _ = db.execute("DELETE FROM feature_requests WHERE id = ?", [id])
        _ = db.execute("DELETE FROM feature_request_comments WHERE feature_request_id = ?", [id])
        refresh()
    }

    private func loadFeatureRequestComments() -> [FeatureRequestComment] {
        db.query("SELECT * FROM feature_request_comments ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let requestID = row["feature_request_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return FeatureRequestComment(
                id: id,
                featureRequestId: requestID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func featureRequestComments(for requestID: Int) -> [FeatureRequestComment] {
        featureRequestComments
            .filter { $0.featureRequestId == requestID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addFeatureRequestComment(requestID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO feature_request_comments (feature_request_id, body, created_at) VALUES (?, ?, ?)",
            [requestID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteFeatureRequestComment(_ id: Int) {
        _ = db.execute("DELETE FROM feature_request_comments WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Table tracker

    private func loadTableTrackers() -> [TableTracker] {
        db.query("SELECT * FROM table_trackers ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return TableTracker(id: id, name: name, createdAt: Date(timeIntervalSince1970: created), updatedAt: Date(timeIntervalSince1970: updated))
        }
    }

    private func loadTableRows() -> [TableRow] {
        db.query("SELECT * FROM table_tracker_rows ORDER BY position ASC, id ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let tableID = row["tracker_id"] as? Int,
                let label = row["label"] as? String,
                let position = row["position"] as? Int
            else { return nil }
            return TableRow(id: id, tableId: tableID, label: label, position: position)
        }
    }

    private func loadTableCells() -> [TableCell] {
        db.query("SELECT * FROM table_tracker_cells").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let tableID = row["tracker_id"] as? Int,
                let rowID = row["row_id"] as? Int,
                let day = row["day"] as? String
            else { return nil }
            return TableCell(id: id, tableId: tableID, rowId: rowID, day: day, done: (row["done"] as? Int) == 1)
        }
    }

    func tableRows(for tableID: Int) -> [TableRow] {
        tableRows.filter { $0.tableId == tableID }.sorted { $0.position < $1.position }
    }

    func tableTracker(_ t: TableTracker, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        let matchingRows = tableRows.filter { $0.tableId == t.id && $0.label.lowercased().contains(q) }
        return t.name.lowercased().contains(q) || !matchingRows.isEmpty
    }

    @discardableResult
    func addTableTracker(name: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO table_trackers (name, created_at, updated_at) VALUES (?, ?, ?)",
            [trimmed, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func renameTableTracker(id: Int, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE table_trackers SET name = ?, updated_at = ? WHERE id = ?", [trimmed, Date().timeIntervalSince1970, id])
        refresh()
    }

    func deleteTableTracker(_ id: Int) {
        _ = db.execute("DELETE FROM table_trackers WHERE id = ?", [id])
        _ = db.execute("DELETE FROM table_tracker_rows WHERE tracker_id = ?", [id])
        _ = db.execute("DELETE FROM table_tracker_cells WHERE tracker_id = ?", [id])
        refresh()
    }

    @discardableResult
    func addTableRow(tableID: Int, label: String) -> Int? {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (tableRows.filter { $0.tableId == tableID }.map(\.position).max() ?? -1) + 1
        _ = db.execute(
            "INSERT INTO table_tracker_rows (tracker_id, label, position, created_at) VALUES (?, ?, ?, ?)",
            [tableID, trimmed, maxPos, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func renameTableRow(id: Int, label: String) {
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE table_tracker_rows SET label = ? WHERE id = ?", [trimmed, id])
        refresh()
    }

    func deleteTableRow(id: Int) {
        _ = db.execute("DELETE FROM table_tracker_rows WHERE id = ?", [id])
        _ = db.execute("DELETE FROM table_tracker_cells WHERE row_id = ?", [id])
        refresh()
    }

    func moveTableRow(id: Int, direction: Int) {
        let list = tableRows.filter { $0.id == id }.map { $0.tableId }.first.flatMap { tid in tableRows(for: tid) }
        guard let rows = list, let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < rows.count else { return }
        let other = rows[target]
        _ = db.execute("UPDATE table_tracker_rows SET position = ? WHERE id = ?", [other.position, id])
        _ = db.execute("UPDATE table_tracker_rows SET position = ? WHERE id = ?", [rows[index].position, other.id])
        refresh()
    }

    func isCellDone(tableID: Int, rowID: Int, day: String) -> Bool {
        tableCells.contains { $0.tableId == tableID && $0.rowId == rowID && $0.day == day && $0.done }
    }

    func toggleCell(tableID: Int, rowID: Int, day: String) {
        if let cell = tableCells.first(where: { $0.tableId == tableID && $0.rowId == rowID && $0.day == day }) {
            _ = db.execute("UPDATE table_tracker_cells SET done = ? WHERE id = ?", [cell.done ? 0 : 1, cell.id])
        } else {
            _ = db.execute(
                "INSERT INTO table_tracker_cells (tracker_id, row_id, day, done) VALUES (?, ?, ?, 1)",
                [tableID, rowID, day]
            )
        }
        refresh()
    }

    func tableDoneCount(tableID: Int, rowID: Int, in days: [String]) -> Int {
        let keys = Set(days)
        return tableCells.filter { $0.tableId == tableID && $0.rowId == rowID && keys.contains($0.day) && $0.done }.count
    }

    // MARK: - Pending list

    private func loadPendingItems() -> [PendingItem] {
        db.query("SELECT * FROM pending_items ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let note = row["note"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return PendingItem(
                id: id,
                title: title,
                note: note,
                done: (row["done"] as? Int) == 1,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func pendingItem(_ p: PendingItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.title.lowercased().contains(q) || p.note.lowercased().contains(q)
    }

    @discardableResult
    func addPendingItem(title: String, note: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (pendingItems.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO pending_items (title, note, done, position, created_at, updated_at) VALUES (?, ?, 0, ?, ?, ?)",
            [trimmed, note, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updatePendingItem(id: Int, title: String, note: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE pending_items SET title = ?, note = ?, updated_at = ? WHERE id = ?",
            [trimmed, note, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func togglePendingItemDone(_ id: Int) {
        guard let item = pendingItems.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE pending_items SET done = ?, updated_at = ? WHERE id = ?", [item.done ? 0 : 1, Date().timeIntervalSince1970, id])
        refresh()
    }

    func movePendingItem(id: Int, direction: Int) {
        let list = pendingItems.filter { !$0.done }.sorted { $0.position < $1.position }
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE pending_items SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE pending_items SET position = ?, updated_at = ? WHERE id = ?", [list[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deletePendingItem(_ id: Int) {
        _ = db.execute("DELETE FROM pending_items WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Diet

    private func loadDietEntries() -> [DietEntry] {
        db.query("SELECT * FROM diet_entries ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let day = row["day"] as? String,
                let mealRaw = row["meal"] as? String,
                let meal = DietMeal(rawValue: mealRaw),
                let food = row["food"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return DietEntry(
                id: id,
                day: day,
                meal: meal,
                food: food,
                note: row["note"] as? String ?? "",
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func dietEntries(for day: String) -> [DietEntry] {
        dietEntries.filter { $0.day == day }.sorted { $0.createdAt < $1.createdAt }
    }

    func dietEntries(for meal: DietMeal, on day: String) -> [DietEntry] {
        dietEntries.filter { $0.day == day && $0.meal == meal }.sorted { $0.createdAt < $1.createdAt }
    }

    func dietEntry(_ e: DietEntry, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return e.food.lowercased().contains(q) || e.note.lowercased().contains(q) || e.meal.displayName.lowercased().contains(q)
    }

    @discardableResult
    func addDietEntry(day: String, meal: DietMeal, food: String, note: String) -> Int? {
        let trimmed = food.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        _ = db.execute(
            "INSERT INTO diet_entries (day, meal, food, note, created_at) VALUES (?, ?, ?, ?, ?)",
            [day, meal.rawValue, trimmed, note, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateDietEntry(id: Int, food: String, note: String) {
        let trimmed = food.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE diet_entries SET food = ?, note = ? WHERE id = ?", [trimmed, note, id])
        refresh()
    }

    func deleteDietEntry(_ id: Int) {
        _ = db.execute("DELETE FROM diet_entries WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Family

    var sortedFamilyMembers: [FamilyMember] {
        familyMembers.sorted { $0.position < $1.position }
    }

    func familyComments(for memberID: Int) -> [FamilyComment] {
        familyComments
            .filter { $0.memberId == memberID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func addFamilyComment(memberID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO family_comments (member_id, body, created_at) VALUES (?, ?, ?)",
            [memberID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteFamilyComment(_ id: Int) {
        _ = db.execute("DELETE FROM family_comments WHERE id = ?", [id])
        refresh()
    }

    private func loadFamilyComments() -> [FamilyComment] {
        db.query("SELECT * FROM family_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let memberID = row["member_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return FamilyComment(
                id: id,
                memberId: memberID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadFamilyMembers() -> [FamilyMember] {
        db.query("SELECT * FROM family_members ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let relation = row["relation"] as? String,
                let birthday = row["birthday"] as? String,
                let note = row["note"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return FamilyMember(
                id: id,
                name: name,
                relation: relation,
                birthday: birthday,
                note: note,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func familyMember(_ m: FamilyMember, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return m.name.lowercased().contains(q) || m.relation.lowercased().contains(q) || m.note.lowercased().contains(q)
    }

    @discardableResult
    func addFamilyMember(name: String, relation: String, birthday: String, note: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (familyMembers.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO family_members (name, relation, birthday, note, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [trimmed, relation, birthday, note, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateFamilyMember(id: Int, name: String, relation: String, birthday: String, note: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE family_members SET name = ?, relation = ?, birthday = ?, note = ?, updated_at = ? WHERE id = ?",
            [trimmed, relation, birthday, note, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveFamilyMember(id: Int, direction: Int) {
        let list = sortedFamilyMembers
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE family_members SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE family_members SET position = ?, updated_at = ? WHERE id = ?", [list[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteFamilyMember(_ id: Int) {
        _ = db.execute("DELETE FROM family_comments WHERE member_id = ?", [id])
        _ = db.execute("DELETE FROM family_members WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Follow-ups

    var openFollowUps: [FollowUp] {
        followUps.filter { !$0.done }
    }

    var doneFollowUps: [FollowUp] {
        followUps.filter(\.done)
    }

    private func loadFollowUps() -> [FollowUp] {
        db.query("SELECT * FROM followups ORDER BY done ASC, date ASC, position ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let note = row["note"] as? String,
                let date = row["date"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return FollowUp(
                id: id,
                title: title,
                note: note,
                date: date,
                done: (row["done"] as? Int) == 1,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func followUp(_ f: FollowUp, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return f.title.lowercased().contains(q) || f.note.lowercased().contains(q) || f.dateText.lowercased().contains(q)
    }

    func followUpsSorted(_ includeDone: Bool) -> [FollowUp] {
        var list = openFollowUps
        if includeDone {
            list += doneFollowUps.sorted { $0.updatedAt > $1.updatedAt }
        }
        return list
    }

    @discardableResult
    func addFollowUp(title: String, note: String, date: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (followUps.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO followups (title, note, date, done, position, created_at, updated_at) VALUES (?, ?, ?, 0, ?, ?, ?)",
            [trimmed, note, date, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateFollowUp(id: Int, title: String, note: String, date: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE followups SET title = ?, note = ?, date = ?, updated_at = ? WHERE id = ?",
            [trimmed, note, date, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func toggleFollowUpDone(_ id: Int) {
        guard let item = followUps.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE followups SET done = ?, updated_at = ? WHERE id = ?", [item.done ? 0 : 1, Date().timeIntervalSince1970, id])
        refresh()
    }

    func deleteFollowUp(_ id: Int) {
        _ = db.execute("DELETE FROM followups WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Inspirations

    var sortedInspirations: [Inspiration] {
        inspirations.sorted { $0.position < $1.position }
    }

    private func loadInspirations() -> [Inspiration] {
        db.query("SELECT * FROM inspirations ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let text = row["text"] as? String,
                let source = row["source"] as? String,
                let note = row["note"] as? String,
                let link = row["link"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Inspiration(
                id: id,
                text: text,
                source: source,
                note: note,
                link: link,
                bookmarked: (row["bookmarked"] as? Int) == 1,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func inspiration(_ i: Inspiration, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return i.text.lowercased().contains(q) || i.source.lowercased().contains(q) || i.note.lowercased().contains(q) || i.link.lowercased().contains(q)
    }

    @discardableResult
    func addInspiration(text: String, source: String, note: String, link: String) -> Int? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (inspirations.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO inspirations (text, source, note, link, bookmarked, position, created_at, updated_at) VALUES (?, ?, ?, ?, 0, ?, ?, ?)",
            [trimmed, source, note, link, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateInspiration(id: Int, text: String, source: String, note: String, link: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE inspirations SET text = ?, source = ?, note = ?, link = ?, updated_at = ? WHERE id = ?",
            [trimmed, source, note, link, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func toggleInspirationBookmark(_ id: Int) {
        guard let item = inspirations.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE inspirations SET bookmarked = ?, updated_at = ? WHERE id = ?", [item.bookmarked ? 0 : 1, Date().timeIntervalSince1970, id])
        refresh()
    }

    func moveInspiration(id: Int, direction: Int) {
        let list = sortedInspirations
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE inspirations SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE inspirations SET position = ?, updated_at = ? WHERE id = ?", [list[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteInspiration(_ id: Int) {
        _ = db.execute("DELETE FROM inspirations WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Mini Airtable

    private func loadAirtables() -> [Airtable] {
        db.query("SELECT * FROM airtables ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Airtable(id: id, name: name, position: position, createdAt: Date(timeIntervalSince1970: created), updatedAt: Date(timeIntervalSince1970: updated))
        }
    }

    private func loadAirtableColumns() -> [AirtableColumn] {
        db.query("SELECT * FROM airtable_columns ORDER BY position ASC, id ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let airtableID = row["airtable_id"] as? Int,
                let name = row["name"] as? String,
                let typeRaw = row["type"] as? String,
                let type = AirtableColType(rawValue: typeRaw),
                let position = row["position"] as? Int
            else { return nil }
            return AirtableColumn(id: id, airtableId: airtableID, name: name, type: type, position: position)
        }
    }

    private func loadAirtableRows() -> [AirtableRow] {
        db.query("SELECT * FROM airtable_rows ORDER BY position ASC, id ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let airtableID = row["airtable_id"] as? Int,
                let position = row["position"] as? Int
            else { return nil }
            return AirtableRow(id: id, airtableId: airtableID, position: position)
        }
    }

    private func loadAirtableCells() -> [AirtableCell] {
        db.query("SELECT * FROM airtable_cells").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let rowID = row["row_id"] as? Int,
                let columnID = row["column_id"] as? Int
            else { return nil }
            return AirtableCell(id: id, rowId: rowID, columnId: columnID, value: row["value"] as? String ?? "")
        }
    }

    func airtableColumns(for airtableID: Int) -> [AirtableColumn] {
        airtableColumns.filter { $0.airtableId == airtableID }.sorted { $0.position < $1.position }
    }

    func airtableRows(for airtableID: Int) -> [AirtableRow] {
        airtableRows.filter { $0.airtableId == airtableID }.sorted { $0.position < $1.position }
    }

    func airtable(_ t: Airtable, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return t.name.lowercased().contains(query.lowercased())
    }

    func cellValue(rowID: Int, columnID: Int) -> String {
        airtableCells.first { $0.rowId == rowID && $0.columnId == columnID }?.value ?? ""
    }

    func cellIsChecked(rowID: Int, columnID: Int) -> Bool {
        cellValue(rowID: rowID, columnID: columnID) == "1"
    }

    func setCellValue(rowID: Int, columnID: Int, _ value: String) {
        if let cell = airtableCells.first(where: { $0.rowId == rowID && $0.columnId == columnID }) {
            _ = db.execute("UPDATE airtable_cells SET value = ? WHERE id = ?", [value, cell.id])
        } else {
            _ = db.execute(
                "INSERT INTO airtable_cells (row_id, column_id, value) VALUES (?, ?, ?)",
                [rowID, columnID, value]
            )
        }
        refresh()
    }

    @discardableResult
    func addAirtable(name: String) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (airtables.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO airtables (name, position, created_at, updated_at) VALUES (?, ?, ?, ?)", [trimmed, maxPos, now, now])
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func renameAirtable(id: Int, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE airtables SET name = ?, updated_at = ? WHERE id = ?", [trimmed, Date().timeIntervalSince1970, id])
        refresh()
    }

    func deleteAirtable(_ id: Int) {
        let rows = airtableRows.filter { $0.airtableId == id }
        let rowIDs = rows.map(\.id)
        _ = db.execute("DELETE FROM airtables WHERE id = ?", [id])
        _ = db.execute("DELETE FROM airtable_columns WHERE airtable_id = ?", [id])
        _ = db.execute("DELETE FROM airtable_rows WHERE airtable_id = ?", [id])
        for rid in rowIDs {
            _ = db.execute("DELETE FROM airtable_cells WHERE row_id = ?", [rid])
        }
        refresh()
    }

    @discardableResult
    func addAirtableColumn(airtableID: Int, name: String, type: AirtableColType) -> Int? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (airtableColumns.filter { $0.airtableId == airtableID }.map(\.position).max() ?? -1) + 1
        _ = db.execute(
            "INSERT INTO airtable_columns (airtable_id, name, type, position, created_at) VALUES (?, ?, ?, ?, ?)",
            [airtableID, trimmed, type.rawValue, maxPos, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func renameAirtableColumn(id: Int, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute("UPDATE airtable_columns SET name = ? WHERE id = ?", [trimmed, id])
        refresh()
    }

    func changeAirtableColumnType(id: Int, type: AirtableColType) {
        _ = db.execute("UPDATE airtable_columns SET type = ? WHERE id = ?", [type.rawValue, id])
        refresh()
    }

    func deleteAirtableColumn(id: Int) {
        _ = db.execute("DELETE FROM airtable_columns WHERE id = ?", [id])
        _ = db.execute("DELETE FROM airtable_cells WHERE column_id = ?", [id])
        refresh()
    }

    func moveAirtableColumn(id: Int, direction: Int) {
        let list = airtableColumns.filter { $0.id == id }.map { $0.airtableId }.first.flatMap { tid in airtableColumns(for: tid) }
        guard let cols = list, let index = cols.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < cols.count else { return }
        let other = cols[target]
        _ = db.execute("UPDATE airtable_columns SET position = ? WHERE id = ?", [other.position, id])
        _ = db.execute("UPDATE airtable_columns SET position = ? WHERE id = ?", [cols[index].position, other.id])
        refresh()
    }

    @discardableResult
    func addAirtableRow(airtableID: Int) -> Int? {
        let maxPos = (airtableRows.filter { $0.airtableId == airtableID }.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute("INSERT INTO airtable_rows (airtable_id, position, created_at, updated_at) VALUES (?, ?, ?, ?)", [airtableID, maxPos, now, now])
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func deleteAirtableRow(id: Int) {
        _ = db.execute("DELETE FROM airtable_rows WHERE id = ?", [id])
        _ = db.execute("DELETE FROM airtable_cells WHERE row_id = ?", [id])
        refresh()
    }

    func moveAirtableRow(id: Int, direction: Int) {
        let list = airtableRows.filter { $0.id == id }.map { $0.airtableId }.first.flatMap { tid in airtableRows(for: tid) }
        guard let rows = list, let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < rows.count else { return }
        let other = rows[target]
        _ = db.execute("UPDATE airtable_rows SET position = ? WHERE id = ?", [other.position, id])
        _ = db.execute("UPDATE airtable_rows SET position = ? WHERE id = ?", [rows[index].position, other.id])
        refresh()
    }

    // MARK: - Mini video hosting

    var sortedHostedVideos: [HostedVideo] {
        hostedVideos.sorted { $0.position < $1.position }
    }

    private func loadHostedVideos() -> [HostedVideo] {
        db.query("SELECT * FROM hosted_videos ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let description = row["description"] as? String,
                let url = row["url"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return HostedVideo(
                id: id,
                title: title,
                description: description,
                url: url,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadHostedVideoComments() -> [HostedVideoComment] {
        db.query("SELECT * FROM hosted_video_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let videoID = row["video_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return HostedVideoComment(
                id: id,
                videoId: videoID,
                parentId: row["parent_id"] as? Int,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func hostedVideo(_ v: HostedVideo, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return v.title.lowercased().contains(q) || v.description.lowercased().contains(q)
    }

    @discardableResult
    func addHostedVideo(title: String, description: String, url: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (hostedVideos.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO hosted_videos (title, description, url, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [trimmed, description, url, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateHostedVideo(id: Int, title: String, description: String, url: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE hosted_videos SET title = ?, description = ?, url = ?, updated_at = ? WHERE id = ?",
            [trimmed, description, url, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveHostedVideo(id: Int, direction: Int) {
        let list = sortedHostedVideos
        guard let index = list.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < list.count else { return }
        let other = list[target]
        _ = db.execute("UPDATE hosted_videos SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE hosted_videos SET position = ?, updated_at = ? WHERE id = ?", [list[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteHostedVideo(_ id: Int) {
        _ = db.execute("DELETE FROM hosted_videos WHERE id = ?", [id])
        _ = db.execute("DELETE FROM hosted_video_comments WHERE video_id = ?", [id])
        refresh()
    }

    func hostedVideoComments(for videoID: Int) -> [HostedVideoComment] {
        hostedVideoComments.filter { $0.videoId == videoID }
    }

    func topLevelHostedComments(for videoID: Int) -> [HostedVideoComment] {
        hostedVideoComments(for: videoID).filter { !$0.isReply }.sorted { $0.createdAt < $1.createdAt }
    }

    func hostedReplies(to commentID: Int) -> [HostedVideoComment] {
        hostedVideoComments.filter { $0.parentId == commentID }.sorted { $0.createdAt < $1.createdAt }
    }

    func hostedReplyCount(to commentID: Int) -> Int {
        hostedVideoComments.filter { $0.parentId == commentID }.count
    }

    func addHostedVideoComment(videoID: Int, parentID: Int?, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO hosted_video_comments (video_id, parent_id, body, created_at) VALUES (?, ?, ?, ?)",
            [videoID, parentID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteHostedVideoComment(_ id: Int) {
        _ = db.execute("DELETE FROM hosted_video_comments WHERE id = ?", [id])
        _ = db.execute("DELETE FROM hosted_video_comments WHERE parent_id = ?", [id])
        refresh()
    }

    // MARK: - Mini Reddit

    private func loadRedditPosts() -> [RedditPost] {
        db.query("SELECT * FROM reddit_posts ORDER BY votes DESC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let body = row["body"] as? String,
                let sub = row["sub"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return RedditPost(
                id: id,
                title: title,
                body: body,
                sub: sub,
                votes: row["votes"] as? Int ?? 0,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadRedditComments() -> [RedditComment] {
        db.query("SELECT * FROM reddit_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let postID = row["post_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return RedditComment(
                id: id,
                postId: postID,
                parentId: row["parent_id"] as? Int,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func redditPost(_ p: RedditPost, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return p.title.lowercased().contains(q) || p.body.lowercased().contains(q) || p.sub.lowercased().contains(q)
    }

    @discardableResult
    func addRedditPost(title: String, body: String, sub: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO reddit_posts (title, body, sub, votes, position, created_at, updated_at) VALUES (?, ?, ?, 0, 0, ?, ?)",
            [trimmed, body, sub, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateRedditPost(id: Int, title: String, body: String, sub: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE reddit_posts SET title = ?, body = ?, sub = ?, updated_at = ? WHERE id = ?",
            [trimmed, body, sub, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func voteRedditPost(id: Int, delta: Int) {
        guard let post = redditPosts.first(where: { $0.id == id }) else { return }
        _ = db.execute("UPDATE reddit_posts SET votes = ?, updated_at = ? WHERE id = ?", [max(0, post.votes + delta), Date().timeIntervalSince1970, id])
        refresh()
    }

    func deleteRedditPost(_ id: Int) {
        _ = db.execute("DELETE FROM reddit_posts WHERE id = ?", [id])
        _ = db.execute("DELETE FROM reddit_comments WHERE post_id = ?", [id])
        refresh()
    }

    func redditComments(for postID: Int) -> [RedditComment] {
        redditComments.filter { $0.postId == postID }
    }

    func topLevelRedditComments(for postID: Int) -> [RedditComment] {
        redditComments(for: postID).filter { !$0.isReply }.sorted { $0.createdAt < $1.createdAt }
    }

    func redditReplies(to commentID: Int) -> [RedditComment] {
        redditComments.filter { $0.parentId == commentID }.sorted { $0.createdAt < $1.createdAt }
    }

    func addRedditComment(postID: Int, parentID: Int?, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO reddit_comments (post_id, parent_id, body, created_at) VALUES (?, ?, ?, ?)",
            [postID, parentID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteRedditComment(_ id: Int) {
        _ = db.execute("DELETE FROM reddit_comments WHERE id = ?", [id])
        _ = db.execute("DELETE FROM reddit_comments WHERE parent_id = ?", [id])
        refresh()
    }

    // MARK: - Events (subscribe & listen)

    private func loadEvents() -> [EventShow] {
        db.query("SELECT * FROM events ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let description = row["description"] as? String,
                let subscribedRaw = row["subscribed"] as? Int,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return EventShow(
                id: id,
                title: title,
                description: description,
                subscribed: subscribedRaw != 0,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadEventEpisodes() -> [EventEpisode] {
        db.query("SELECT * FROM event_episodes ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let eventID = row["event_id"] as? Int,
                let title = row["title"] as? String,
                let note = row["note"] as? String,
                let filename = row["filename"] as? String,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return EventEpisode(
                id: id,
                eventId: eventID,
                title: title,
                note: note,
                filename: filename,
                duration: row["duration"] as? Double ?? 0,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func eventShow(_ e: EventShow, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return e.title.lowercased().contains(q) || e.description.lowercased().contains(q)
    }

    func episodes(for eventID: Int) -> [EventEpisode] {
        eventEpisodes.filter { $0.eventId == eventID }.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func addEvent(title: String, description: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO events (title, description, subscribed, position, created_at, updated_at) VALUES (?, ?, 1, ?, ?, ?)",
            [trimmed, description, events.count, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateEvent(id: Int, title: String, description: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE events SET title = ?, description = ?, updated_at = ? WHERE id = ?",
            [trimmed, description, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func toggleSubscribed(id: Int) {
        guard let event = events.first(where: { $0.id == id }) else { return }
        _ = db.execute(
            "UPDATE events SET subscribed = ?, updated_at = ? WHERE id = ?",
            [event.subscribed ? 0 : 1, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveEvent(id: Int, direction: Int) {
        let sorted = events
        guard let index = sorted.firstIndex(where: { $0.id == id }) else { return }
        let targetIndex = index + direction
        guard targetIndex >= 0 && targetIndex < sorted.count else { return }
        let other = sorted[targetIndex]
        _ = db.execute("UPDATE events SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE events SET position = ?, updated_at = ? WHERE id = ?", [sorted[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteEvent(_ id: Int) {
        let episodeFiles = episodes(for: id)
        _ = db.execute("DELETE FROM events WHERE id = ?", [id])
        _ = db.execute("DELETE FROM event_episodes WHERE event_id = ?", [id])
        for episode in episodeFiles {
            let file = audioDirectoryURL.appendingPathComponent(episode.filename)
            try? FileManager.default.removeItem(at: file)
        }
        if nowPlayingEventID == id {
            stopPlayback()
        }
        refresh()
    }

    @discardableResult
    func addEpisode(eventID: Int, title: String, note: String, from sourceURL: URL) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date().timeIntervalSince1970
        let filename = UUID().uuidString + "." + sourceURL.pathExtension
        let dest = audioDirectoryURL.appendingPathComponent(filename)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: dest)
        } catch {
            return nil
        }
        let duration = durationOfAudio(at: dest)
        _ = db.execute(
            "INSERT INTO event_episodes (event_id, title, note, filename, duration, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
            [eventID, trimmed.isEmpty ? "Untitled episode" : trimmed, note, filename, duration, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateEpisode(id: Int, title: String, note: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE event_episodes SET title = ?, note = ?, updated_at = ? WHERE id = ?",
            [trimmed, note, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteEpisode(_ id: Int) {
        guard let episode = eventEpisodes.first(where: { $0.id == id }) else { return }
        let file = audioDirectoryURL.appendingPathComponent(episode.filename)
        try? FileManager.default.removeItem(at: file)
        _ = db.execute("DELETE FROM event_episodes WHERE id = ?", [id])
        if nowPlayingEpisodeID == id {
            stopPlayback()
        }
        refresh()
    }

    private func durationOfAudio(at url: URL) -> Double {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return 0 }
        return player.duration
    }

    // MARK: Playback

    func playEpisode(eventID: Int, episodeID: Int) {
        guard let episode = eventEpisodes.first(where: { $0.id == episodeID }) else { return }
        let file = audioDirectoryURL.appendingPathComponent(episode.filename)
        guard let player = try? AVAudioPlayer(contentsOf: file) else { return }
        stopPlayback()
        audioPlayer = player
        audioPlayer?.play()
        nowPlayingEpisodeID = episodeID
        nowPlayingEventID = eventID
        isPlaying = true
        audioPlaybackTime = 0
    }

    func handlePlaybackFinished() {
        audioPlaybackTime = audioPlayer?.duration ?? 0
        isPlaying = false
        audioPlayer = nil
        nowPlayingAudioNoteID = nil
    }

    func togglePlayback() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seekPlayback(to seconds: TimeInterval) {
        audioPlayer?.currentTime = seconds
        audioPlaybackTime = seconds
    }

    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        nowPlayingEpisodeID = nil
        nowPlayingEventID = nil
        nowPlayingAudioNoteID = nil
        isPlaying = false
        audioPlaybackTime = 0
    }

    // MARK: - Mini Tree

    private func loadTreeNodes() -> [TreeNode] {
        db.query("SELECT * FROM tree_nodes ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let note = row["note"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return TreeNode(
                id: id,
                parentId: row["parent_id"] as? Int,
                title: title,
                note: note,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func treeNode(_ n: TreeNode, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return n.title.lowercased().contains(q) || n.note.lowercased().contains(q)
    }

    func rootTreeNodes() -> [TreeNode] {
        treeNodes.filter { $0.parentId == nil }
    }

    func treeChildren(of parentID: Int) -> [TreeNode] {
        treeNodes.filter { $0.parentId == parentID }
    }

    func hasTreeChildren(_ nodeID: Int) -> Bool {
        treeNodes.contains { $0.parentId == nodeID }
    }

    func treeDepth(of nodeID: Int) -> Int {
        var depth = 0
        var currentID: Int? = nodeID
        while let id = currentID, let node = treeNodes.first(where: { $0.id == id }), let parent = node.parentId {
            depth += 1
            currentID = parent
            if depth > 100 { break }
        }
        return depth
    }

    @discardableResult
    func addTreeNode(parentID: Int?, title: String, note: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let siblings = parentID.map { treeChildren(of: $0) } ?? rootTreeNodes()
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO tree_nodes (parent_id, title, note, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
            [parentID, trimmed, note, siblings.count, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateTreeNode(id: Int, title: String, note: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE tree_nodes SET title = ?, note = ?, updated_at = ? WHERE id = ?",
            [trimmed, note, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveTreeNode(id: Int, direction: Int) {
        guard let node = treeNodes.first(where: { $0.id == id }) else { return }
        let siblings = node.parentId.map { treeChildren(of: $0) } ?? rootTreeNodes()
        guard let index = siblings.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < siblings.count else { return }
        let other = siblings[target]
        _ = db.execute("UPDATE tree_nodes SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE tree_nodes SET position = ?, updated_at = ? WHERE id = ?", [siblings[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteTreeNode(_ id: Int) {
        var toDelete = [id]
        var index = 0
        while index < toDelete.count {
            let current = toDelete[index]
            toDelete.append(contentsOf: treeNodes.filter { $0.parentId == current }.map { $0.id })
            index += 1
        }
        for nodeID in toDelete {
            _ = db.execute("DELETE FROM tree_nodes WHERE id = ?", [nodeID])
        }
        refresh()
    }

    // MARK: - FAQ

    private func loadFaqs() -> [Faq] {
        db.query("SELECT * FROM faqs ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let youtube = row["youtube_url"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return Faq(
                id: id,
                title: title,
                youtubeURL: youtube,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    private func loadFaqEntries() -> [FaqEntry] {
        db.query("SELECT * FROM faq_entries ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let faqID = row["faq_id"] as? Int,
                let question = row["question"] as? String,
                let answer = row["answer"] as? String,
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return FaqEntry(
                id: id,
                faqId: faqID,
                question: question,
                answer: answer,
                position: position,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func faq(_ f: Faq, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return f.title.lowercased().contains(q)
    }

    func faqEntries(for faqID: Int) -> [FaqEntry] {
        faqEntries.filter { $0.faqId == faqID }
    }

    @discardableResult
    func addFaq(title: String, youtubeURL: String, pastedFAQ: String) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO faqs (title, youtube_url, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
            [trimmed, youtubeURL, faqs.count, now, now]
        )
        let id = db.lastInsertID()
        let entries = parseFaqText(pastedFAQ)
        for (index, pair) in entries.enumerated() {
            _ = db.execute(
                "INSERT INTO faq_entries (faq_id, question, answer, position, created_at) VALUES (?, ?, ?, ?, ?)",
                [id, pair.question, pair.answer, index, now]
            )
        }
        refresh()
        return id
    }

    func updateFaq(id: Int, title: String, youtubeURL: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE faqs SET title = ?, youtube_url = ?, updated_at = ? WHERE id = ?",
            [trimmed, youtubeURL, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func moveFaq(id: Int, direction: Int) {
        guard let index = faqs.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < faqs.count else { return }
        let other = faqs[target]
        _ = db.execute("UPDATE faqs SET position = ?, updated_at = ? WHERE id = ?", [other.position, Date().timeIntervalSince1970, id])
        _ = db.execute("UPDATE faqs SET position = ?, updated_at = ? WHERE id = ?", [faqs[index].position, Date().timeIntervalSince1970, other.id])
        refresh()
    }

    func deleteFaq(_ id: Int) {
        _ = db.execute("DELETE FROM faqs WHERE id = ?", [id])
        _ = db.execute("DELETE FROM faq_entries WHERE faq_id = ?", [id])
        refresh()
    }

    @discardableResult
    func addFaqEntry(faqID: Int, question: String, answer: String) -> Int? {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let entries = faqEntries(for: faqID)
        _ = db.execute(
            "INSERT INTO faq_entries (faq_id, question, answer, position, created_at) VALUES (?, ?, ?, ?, ?)",
            [faqID, trimmed, answer, entries.count, Date().timeIntervalSince1970]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateFaqEntry(id: Int, question: String, answer: String) {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE faq_entries SET question = ?, answer = ? WHERE id = ?",
            [trimmed, answer, id]
        )
        refresh()
    }

    func moveFaqEntry(id: Int, faqID: Int, direction: Int) {
        let entries = faqEntries(for: faqID)
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let target = index + direction
        guard target >= 0, target < entries.count else { return }
        let other = entries[target]
        _ = db.execute("UPDATE faq_entries SET position = ? WHERE id = ?", [other.position, id])
        _ = db.execute("UPDATE faq_entries SET position = ? WHERE id = ?", [entries[index].position, other.id])
        refresh()
    }

    func deleteFaqEntry(_ id: Int) {
        _ = db.execute("DELETE FROM faq_entries WHERE id = ?", [id])
        refresh()
    }

    func parseFaqText(_ text: String) -> [(question: String, answer: String)] {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let regex = try? NSRegularExpression(pattern: "^Q\\s*\\d+[\\.\\):]\\s*") else { return [] }
        var result: [(question: String, answer: String)] = []
        var currentQuestion: String?
        var currentAnswer: [String] = []
        for line in lines {
            if let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) {
                if let question = currentQuestion {
                    result.append((question, currentAnswer.joined(separator: "\n")))
                }
                guard let range = Range(match.range, in: line) else { continue }
                currentQuestion = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                currentAnswer = []
            } else if !line.isEmpty {
                currentAnswer.append(line)
            }
        }
        if let question = currentQuestion {
            result.append((question, currentAnswer.joined(separator: "\n")))
        }
        return result
    }

    private func loadChallengeComments() -> [ChallengeComment] {
        db.query("SELECT * FROM challenge_comments ORDER BY created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let challengeID = row["challenge_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return ChallengeComment(
                id: id,
                challengeId: challengeID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    func challengeComments(for challengeID: Int) -> [ChallengeComment] {
        challengeComments
            .filter { $0.challengeId == challengeID }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addChallengeComment(challengeID: Int, body: String) {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "INSERT INTO challenge_comments (challenge_id, body, created_at) VALUES (?, ?, ?)",
            [challengeID, trimmed, Date().timeIntervalSince1970]
        )
        refresh()
    }

    func deleteChallengeComment(_ id: Int) {
        _ = db.execute("DELETE FROM challenge_comments WHERE id = ?", [id])
        refresh()
    }

    // MARK: - Roadmap

    private func loadRoadmap() -> [RoadmapItem] {
        db.query("SELECT * FROM roadmap_items ORDER BY position ASC, created_at DESC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let body = row["body"] as? String,
                let statusRaw = row["status"] as? String,
                let status = RoadmapStatus(rawValue: statusRaw),
                let priorityRaw = row["priority"] as? String,
                let priority = RoadmapPriority(rawValue: priorityRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double,
                let updated = row["updated_at"] as? Double
            else { return nil }
            return RoadmapItem(
                id: id,
                title: title,
                body: body,
                status: status,
                quarter: row["quarter"] as? String ?? "",
                priority: priority,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: updated)
            )
        }
    }

    func roadmapItem(_ r: RoadmapItem, matches query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let q = query.lowercased()
        return r.title.lowercased().contains(q) || r.body.lowercased().contains(q) || r.quarter.lowercased().contains(q)
    }

    func roadmapItems(for status: RoadmapStatus) -> [RoadmapItem] {
        roadmap.filter { $0.status == status }
    }

    @discardableResult
    func addRoadmapItem(title: String, body: String, status: RoadmapStatus, quarter: String, priority: RoadmapPriority) -> Int? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let maxPos = (roadmap.map(\.position).max() ?? -1) + 1
        let now = Date().timeIntervalSince1970
        _ = db.execute(
            "INSERT INTO roadmap_items (title, body, status, quarter, priority, position, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            [trimmed, body, status.rawValue, quarter, priority.rawValue, maxPos, now, now]
        )
        let id = db.lastInsertID()
        refresh()
        return id
    }

    func updateRoadmapItem(id: Int, title: String, body: String, quarter: String, priority: RoadmapPriority) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        _ = db.execute(
            "UPDATE roadmap_items SET title = ?, body = ?, quarter = ?, priority = ?, updated_at = ? WHERE id = ?",
            [trimmed, body, quarter, priority.rawValue, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func setRoadmapStatus(id: Int, status: RoadmapStatus) {
        _ = db.execute(
            "UPDATE roadmap_items SET status = ?, position = ?, updated_at = ? WHERE id = ?",
            [status.rawValue, (roadmap.map(\.position).max() ?? 0) + 1, Date().timeIntervalSince1970, id]
        )
        refresh()
    }

    func deleteRoadmapItem(_ id: Int) {
        _ = db.execute("DELETE FROM roadmap_items WHERE id = ?", [id])
        refresh()
    }

    private func loadThoughts() -> [Thought] {
        db.query("SELECT * FROM thoughts ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let listRaw = row["list"] as? String,
                let list = ThoughtList(rawValue: listRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Thought(
                id: id,
                title: title,
                note: row["note"] as? String ?? "",
                list: list,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadVideos() -> [Video] {
        db.query("SELECT * FROM videos ORDER BY position ASC, created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let title = row["title"] as? String,
                let stageRaw = row["stage"] as? String,
                let stage = VideoStage(rawValue: stageRaw),
                let platformRaw = row["platform"] as? String,
                let platform = VideoPlatform(rawValue: platformRaw),
                let position = row["position"] as? Int,
                let created = row["created_at"] as? Double
            else { return nil }
            return Video(
                id: id,
                title: title,
                note: row["note"] as? String ?? "",
                description: row["description"] as? String ?? "",
                url: row["url"] as? String ?? "",
                platform: platform,
                stage: stage,
                position: position,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadVideoComments() -> [VideoComment] {
        db.query("SELECT * FROM video_comments ORDER BY created_at ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let videoID = row["video_id"] as? Int,
                let body = row["body"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return VideoComment(
                id: id,
                videoId: videoID,
                body: body,
                createdAt: Date(timeIntervalSince1970: created)
            )
        }
    }

    private func loadTrackers() -> [Tracker] {
        db.query("SELECT * FROM trackers ORDER BY sort_order ASC, id ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let name = row["name"] as? String,
                let category = row["category"] as? String,
                let created = row["created_at"] as? Double
            else { return nil }
            return Tracker(
                id: id,
                name: name,
                icon: row["icon"] as? String ?? "checkmark.circle",
                colorName: row["color"] as? String ?? "blue",
                category: category,
                isCounter: (row["is_counter"] as? Int ?? 0) == 1,
                target: row["target"] as? Int ?? 1,
                scheduleNote: row["schedule_note"] as? String ?? "",
                isPreset: (row["is_preset"] as? Int ?? 0) == 1,
                enabled: (row["enabled"] as? Int ?? 1) == 1,
                sortOrder: row["sort_order"] as? Int ?? 0,
                createdAt: Date(timeIntervalSince1970: created),
                updatedAt: Date(timeIntervalSince1970: row["updated_at"] as? Double ?? created)
            )
        }
    }

    private func loadTrackerEntries() -> [TrackerEntry] {
        db.query("SELECT * FROM tracker_entries ORDER BY day ASC").compactMap { row in
            guard
                let id = row["id"] as? Int,
                let trackerID = row["tracker_id"] as? Int,
                let day = row["day"] as? String
            else { return nil }
            return TrackerEntry(
                id: id,
                trackerId: trackerID,
                day: day,
                count: row["count"] as? Int ?? 0,
                note: row["note"] as? String ?? ""
            )
        }
    }
}

struct DailyCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}
