import Foundation
import SwiftUI

enum Platform: String, CaseIterable, Identifiable {
    case x = "x"
    case yt = "yt"
    case ig = "ig"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .x: return "X"
        case .yt: return "YouTube"
        case .ig: return "Instagram"
        }
    }

    var handle: String {
        switch self {
        case .x: return "x.com"
        case .yt: return "yt.com"
        case .ig: return "ig.com"
        }
    }

    var tier: String {
        switch self {
        case .x: return "Primary"
        case .yt: return "Other"
        case .ig: return "Secondary"
        }
    }

    var color: Color {
        switch self {
        case .x: return .blue
        case .yt: return .red
        case .ig: return .pink
        }
    }

    var symbol: String {
        switch self {
        case .x: return "xmark.circle.fill"
        case .yt: return "play.rectangle.fill"
        case .ig: return "camera.aperture"
        }
    }
}

struct Comment: Identifiable {
    let id: Int
    let platform: Platform
    let body: String?
    let url: String?
    let createdAt: Date
    let sessionId: Int?
}

struct Session: Identifiable {
    let id: Int
    let startedAt: Date
    let endedAt: Date?
    let goal: Int
    let commentsAdded: Int

    var isActive: Bool { endedAt == nil }

    var duration: TimeInterval {
        let end = endedAt ?? Date()
        return end.timeIntervalSince(startedAt)
    }
}

struct Milestone: Identifiable {
    let id: Double
    let fraction: Double

    static let all: [Milestone] = [0.01, 0.05, 0.10, 0.25, 0.50, 0.75, 1.00].map {
        Milestone(id: $0, fraction: $0)
    }

    var label: String {
        let pct = Int((fraction * 100).rounded())
        return "\(pct)%"
    }

    var isWin: Bool { fraction <= 0.10 }

    static func reached(by progress: Double) -> Milestone? {
        all.last(where: { $0.fraction <= progress + 0.0001 })
    }

    static func next(after progress: Double) -> Milestone? {
        all.first(where: { $0.fraction > progress + 0.0001 })
    }
}

enum SubGoalPreset: Int, CaseIterable, Identifiable {
    case five = 5
    case ten = 10
    case twenty = 20
    case thirty = 30
    case fifty = 50
    case seventyFive = 75
    case hundred = 100

    var id: Int { rawValue }

    var label: String { "\(rawValue)" }
}

// MARK: - People (Trello-style board)

enum PersonStage: String, CaseIterable, Identifiable {
    case holding = "holding"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    case yearly = "yearly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .holding: return "Holding"
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }

    var group: String {
        self == .holding ? "Holding" : "Check"
    }

    var isHolding: Bool { self == .holding }

    var symbol: String {
        switch self {
        case .holding: return "pause.circle"
        case .daily: return "sun.max"
        case .weekly: return "calendar"
        case .monthly: return "calendar.badge.checkmark"
        case .quarterly: return "calendar.badge.clock"
        case .yearly: return "calendar.badge.exclamationmark"
        }
    }

    var color: Color {
        switch self {
        case .holding: return .gray
        case .daily: return .orange
        case .weekly: return .yellow
        case .monthly: return .teal
        case .quarterly: return .blue
        case .yearly: return .purple
        }
    }
}

struct Person: Identifiable, Equatable {
    let id: Int
    var name: String
    var brief: String
    var description: String
    var stage: PersonStage
    var position: Int
    var createdAt: Date
    var updatedAt: Date
}

enum PersonLinkKind: String, CaseIterable, Identifiable {
    case x, youtube, instagram, video, website, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .x: return "X"
        case .youtube: return "YouTube"
        case .instagram: return "Instagram"
        case .video: return "Video"
        case .website: return "Website"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .x: return "xmark.circle"
        case .youtube: return "play.rectangle"
        case .instagram: return "camera"
        case .video: return "film"
        case .website: return "globe"
        case .other: return "link"
        }
    }
}

struct PersonLink: Identifiable {
    let id: Int
    var personId: Int
    var label: String
    var url: String
    var kind: PersonLinkKind
}

struct PersonComment: Identifiable, Equatable {
    let id: Int
    var personId: Int
    var body: String
    var createdAt: Date
}

// MARK: - Videos (Trello-style board)

enum VideoStage: String, CaseIterable, Identifiable {
    case holding = "holding"
    case urgent = "urgent"
    case important = "important"
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .holding: return "Holding"
        case .urgent: return "Urgent"
        case .important: return "Important"
        case .daily: return "Daily Watch"
        case .weekly: return "Weekly Watch"
        case .monthly: return "Monthly Watch"
        }
    }

    var symbol: String {
        switch self {
        case .holding: return "pause.circle"
        case .urgent: return "exclamationmark.triangle.fill"
        case .important: return "star.fill"
        case .daily: return "sun.max"
        case .weekly: return "calendar"
        case .monthly: return "calendar.badge.clock"
        }
    }

    var color: Color {
        switch self {
        case .holding: return .gray
        case .urgent: return .red
        case .important: return .yellow
        case .daily: return .orange
        case .weekly: return .teal
        case .monthly: return .blue
        }
    }
}

enum VideoPlatform: String, CaseIterable, Identifiable {
    case youtube, x, instagram, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .x: return "X Video"
        case .instagram: return "Instagram Reel"
        case .other: return "Other"
        }
    }

    var symbol: String {
        switch self {
        case .youtube: return "play.rectangle.fill"
        case .x: return "xmark.circle.fill"
        case .instagram: return "camera.aperture"
        case .other: return "link"
        }
    }

    var color: Color {
        switch self {
        case .youtube: return .red
        case .x: return .blue
        case .instagram: return .pink
        case .other: return .gray
        }
    }
}

struct Video: Identifiable, Equatable {
    let id: Int
    var title: String
    var note: String
    var description: String
    var url: String
    var platform: VideoPlatform
    var stage: VideoStage
    var position: Int
    var createdAt: Date
    var updatedAt: Date
}

struct VideoComment: Identifiable, Equatable {
    let id: Int
    var videoId: Int
    var body: String
    var createdAt: Date
}

// MARK: - Thoughts (priority board)

enum ThoughtList: String, CaseIterable, Identifiable {
    case longTerm = "longterm"
    case thisWeek = "thisweek"
    case doing = "doing"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .longTerm: return "Long-term"
        case .thisWeek: return "This week"
        case .doing: return "Doing"
        }
    }

    var symbol: String {
        switch self {
        case .longTerm: return "calendar.badge.clock"
        case .thisWeek: return "calendar"
        case .doing: return "bolt.fill"
        }
    }

    var color: Color {
        switch self {
        case .longTerm: return .purple
        case .thisWeek: return .teal
        case .doing: return .orange
        }
    }
}

struct Thought: Identifiable, Equatable {
    let id: Int
    var title: String
    var note: String
    var list: ThoughtList
    var position: Int
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Wins (celebrated feed)

struct Win: Identifiable, Equatable {
    let id: Int
    var text: String
    var bookmarked: Bool
    var createdAt: Date
}

// MARK: - Fails (didn't-work feed)

struct Fail: Identifiable, Equatable {
    let id: Int
    var text: String
    var bookmarked: Bool
    var createdAt: Date
}

// MARK: - Interstitial Notes (notebook "what am I doing now")

struct InterNote: Identifiable, Equatable {
    let id: Int
    var text: String
    var createdAt: Date
}

// MARK: - Buck (what we're working on)

enum BuckStatus: String, CaseIterable {
    case active, paused, done

    var displayName: String {
        switch self {
        case .active: return "In Flight"
        case .paused: return "On Hold"
        case .done: return "Done"
        }
    }

    var symbol: String {
        switch self {
        case .active: return "bolt.fill"
        case .paused: return "pause.fill"
        case .done: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .active: return .blue
        case .paused: return .orange
        case .done: return .green
        }
    }
}

struct Buck: Identifiable, Equatable {
    let id: Int
    var title: String
    var status: BuckStatus
    var notes: String
    var position: Int
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Focus (what I'm focused on right now)

struct Focus: Identifiable, Equatable {
    let id: Int
    var text: String
    var note: String
    var startedAt: Date
    var endedAt: Date?
    var isActive: Bool {
        endedAt == nil
    }
}

// MARK: - Parallel (3 threads + unorganized catch-all)

struct ParallelItem: Identifiable, Equatable {
    let id: Int
    var lane: Int
    var text: String
    var note: String
    var createdAt: Date

    var laneLabel: String {
        switch lane {
        case 3: return "Unorganized"
        case 1: return "Thing 2"
        case 2: return "Thing 3"
        default: return "Thing 1"
        }
    }
}

// MARK: - Project Tracker

enum ProjectStatus: String, CaseIterable {
    case working, inProgress, completed

    var displayName: String {
        switch self {
        case .working: return "Working"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var symbol: String {
        switch self {
        case .working: return "play.circle.fill"
        case .inProgress: return "pause.circle"
        case .completed: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .working: return .green
        case .inProgress: return .blue
        case .completed: return .gray
        }
    }
}

struct Project: Identifiable, Equatable {
    let id: Int
    var name: String
    var status: ProjectStatus
    var startNote: String
    var stopNote: String
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Deep Work sessions

struct DeepWorkSession: Identifiable, Equatable {
    let id: Int
    var minutes: Int
    var startedAt: Date
    var endedAt: Date
    var completed: Bool
}

let deepWorkPresets: [Int] = [15, 30, 45, 60, 90, 120]

// MARK: - Weekly Schedule

let scheduleSlotNames = ["Morning", "Noon", "Afternoon", "Evening"]

struct ScheduleEntry: Identifiable, Equatable {
    let id: Int
    var day: Int
    var slot: Int
    var task: String
    var updatedAt: Date
}

// MARK: - Holding Hand (parking lot, wins-style)

struct HoldingItem: Identifiable, Equatable {
    let id: Int
    var text: String
    var bookmarked: Bool
    var done: Bool
    var createdAt: Date
}

// MARK: - Urgent (parallel lists by urgency, wins-style)

enum Urgency: Int, CaseIterable, Identifiable {
    case now = 0, today = 1, soon = 2, whenever = 3

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .now: return "Now"
        case .today: return "Today"
        case .soon: return "Soon"
        case .whenever: return "Whenever"
        }
    }

    var color: Color {
        switch self {
        case .now: return .red
        case .today: return .orange
        case .soon: return .yellow
        case .whenever: return .gray
        }
    }

    var symbol: String {
        switch self {
        case .now: return "flame.fill"
        case .today: return "sun.max.fill"
        case .soon: return "clock.fill"
        case .whenever: return "cloud.fill"
        }
    }
}

let allUrgencies: [Urgency] = [.now, .today, .soon, .whenever]

struct UrgentItem: Identifiable, Equatable {
    let id: Int
    var urgency: Urgency
    var text: String
    var note: String
    var position: Int
    var done: Bool
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Mini Mind Map

struct MindMap: Identifiable, Equatable {
    let id: Int
    var title: String
    var createdAt: Date
    var updatedAt: Date
}

let mindMapColorNames = ["red", "orange", "yellow", "green", "blue", "purple", "pink", "teal", "gray"]

func mindMapColor(_ name: String) -> Color {
    switch name {
    case "red": return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green": return .green
    case "purple": return .purple
    case "pink": return .pink
    case "teal": return .teal
    case "gray": return .gray
    default: return .blue
    }
}

struct MindMapNode: Identifiable, Equatable {
    let id: Int
    var mapId: Int
    var parentId: Int?
    var text: String
    var color: String
    var x: Double
    var y: Double
    var createdAt: Date
    var updatedAt: Date

    var isRoot: Bool { parentId == nil }
}

// MARK: - Blog posts

enum BlogPostStatus: String, CaseIterable {
    case draft, published

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .published: return "Published"
        }
    }

    var color: Color {
        switch self {
        case .draft: return .gray
        case .published: return .green
        }
    }
}

struct BlogPost: Identifiable, Equatable {
    let id: Int
    var title: String
    var body: String
    var status: BlogPostStatus
    var tags: String
    var createdAt: Date
    var updatedAt: Date
    var publishedAt: Date?

    var tagList: [String] {
        tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

// MARK: - Mini Slack

struct SlackChannel: Identifiable, Equatable {
    let id: Int
    var name: String
    var color: String
    var createdAt: Date

    var displayName: String { "#\(name)" }
}

struct SlackMessage: Identifiable, Equatable {
    let id: Int
    var channelId: Int
    var author: String
    var text: String
    var createdAt: Date
}

// MARK: - Calendar events

struct CalendarEvent: Identifiable, Equatable {
    let id: Int
    var title: String
    var day: String
    var time: String
    var color: String
    var note: String
    var reminder: Int
    var createdAt: Date
    var updatedAt: Date
}

let calendarReminderPresets: [Int] = [0, 5, 15, 30, 60, 720, 1440]

func calendarReminderLabel(_ minutes: Int) -> String {
    switch minutes {
    case 0: return "None"
    case 5: return "5 min before"
    case 15: return "15 min before"
    case 30: return "30 min before"
    case 60: return "1 hour before"
    case 720: return "12 hours before"
    case 1440: return "1 day before"
    default: return "\(minutes) min before"
    }
}

// MARK: - Year cards (12 cards, one per month)

let yearMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

struct YearCard: Identifiable, Equatable {
    let id: Int
    var slot: Int
    var word: String
    var createdAt: Date
    var updatedAt: Date

    var monthName: String {
        let index = max(0, min(11, slot - 1))
        return yearMonthNames[index]
    }
}

// MARK: - Week cards (52 cards, one per week of the year)

struct WeekCard: Identifiable, Equatable {
    let id: Int
    var slot: Int
    var title: String
    var note: String
    var createdAt: Date
    var updatedAt: Date

    var startDate: Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let jan1 = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()
        return cal.date(byAdding: .day, value: (slot - 1) * 7, to: jan1) ?? jan1
    }

    var endDate: Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let start = startDate
        var end = cal.date(byAdding: .day, value: 6, to: start) ?? start
        if let yearEnd = cal.date(from: DateComponents(year: year, month: 12, day: 31)), end > yearEnd {
            end = yearEnd
        }
        return end
    }

    var monthNumber: Int {
        Calendar.current.component(.month, from: startDate)
    }

    var monthName: String {
        let index = max(0, min(11, monthNumber - 1))
        return yearMonthNames[index]
    }

    var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

// MARK: - Audio notes (voice recordings)

struct AudioNote: Identifiable, Equatable {
    let id: Int
    var title: String
    var filename: String
    var duration: Double
    var createdAt: Date
    var updatedAt: Date

    var durationText: String {
        let total = Int(duration.rounded())
        let m = total / 60
        let s = total % 60
        return m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
}

// MARK: - Challenges

enum ChallengeStatus: String, CaseIterable, Identifiable {
    case active, completed, archived
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }

    var color: Color {
        switch self {
        case .active: return .orange
        case .completed: return .green
        case .archived: return .gray
        }
    }

    var symbol: String {
        switch self {
        case .active: return "bolt.fill"
        case .completed: return "checkmark.seal.fill"
        case .archived: return "archivebox.fill"
        }
    }
}

struct Challenge: Identifiable, Equatable {
    let id: Int
    var title: String
    var body: String
    var status: ChallengeStatus
    var startDate: String
    var endDate: String
    var position: Int
    var createdAt: Date
    var updatedAt: Date

    var dateRangeText: String {
        if startDate.isEmpty && endDate.isEmpty { return "" }
        if startDate.isEmpty { return "by \(endDate)" }
        if endDate.isEmpty { return "from \(startDate)" }
        return "\(startDate) → \(endDate)"
    }
}

struct ChallengeComment: Identifiable, Equatable {
    let id: Int
    var challengeId: Int
    var body: String
    var createdAt: Date
}

struct ChallengePrerequisiteLink: Identifiable, Equatable {
    let id: Int
    var challengeId: Int
    var prerequisiteId: Int
}

// MARK: - Roadmap

enum RoadmapStatus: String, CaseIterable, Identifiable {
    case planned, inProgress, done, deferred
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .planned: return "Planned"
        case .inProgress: return "In Progress"
        case .done: return "Done"
        case .deferred: return "Deferred"
        }
    }

    var color: Color {
        switch self {
        case .planned: return .blue
        case .inProgress: return .orange
        case .done: return .green
        case .deferred: return .gray
        }
    }

    var symbol: String {
        switch self {
        case .planned: return "calendar.badge.plus"
        case .inProgress: return "hammer.fill"
        case .done: return "checkmark.seal.fill"
        case .deferred: return "pause.fill"
        }
    }
}

enum RoadmapPriority: String, CaseIterable, Identifiable {
    case high, medium, low
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var color: Color {
        switch self {
        case .high: return .red
        case .medium: return .orange
        case .low: return .green
        }
    }
}

struct RoadmapItem: Identifiable, Equatable {
    let id: Int
    var title: String
    var body: String
    var status: RoadmapStatus
    var quarter: String
    var priority: RoadmapPriority
    var position: Int
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Links (simple bookmark list)

struct LinkItem: Identifiable, Equatable {
    let id: Int
    var label: String
    var url: String
    var position: Int
    var createdAt: Date
}

// MARK: - 313 Cards (one-word deck)

struct WordCard: Identifiable, Equatable {
    let id: Int
    var slot: Int
    var word: String
    var groupName: String
    var words: [String]
    var link: String
    var createdAt: Date
    var updatedAt: Date

    var wordsText: String {
        words.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: " | ")
    }

    var deckColumns: Int { 10 }
    var row: Int { max(1, (slot - 1) / deckColumns + 1) }
    var col: Int { max(1, (slot - 1) % deckColumns + 1) }
}

// MARK: - Pomodoro

enum PomodoroMode: String, CaseIterable, Identifiable {
    case focus = "focus"
    case short = "short"
    case long = "long"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .focus: return "Focus"
        case .short: return "Short break"
        case .long: return "Long break"
        }
    }

    var minutes: Int {
        switch self {
        case .focus: return 25
        case .short: return 5
        case .long: return 15
        }
    }
}

struct PomodoroSession: Identifiable, Equatable {
    let id: Int
    var mode: PomodoroMode
    var startedAt: Date
    var endedAt: Date?
}

// MARK: - Sprints

enum SprintPreset: Int, CaseIterable, Identifiable {
    case thirty = 30
    case hour = 60
    case twoHours = 120

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .thirty: return "30 minutes"
        case .hour: return "1 hour"
        case .twoHours: return "2 hours"
        }
    }
}

struct Sprint: Identifiable, Equatable {
    let id: Int
    var name: String
    var startAt: Date?
    var endAt: Date?
    var notes: String
    var done: Bool
    var createdAt: Date
    var updatedAt: Date
}

struct Story: Identifiable, Equatable {
    let id: Int
    var sprintId: Int
    var title: String
    var createdAt: Date
    var updatedAt: Date
}

struct StoryTask: Identifiable, Equatable {
    let id: Int
    var storyId: Int
    var title: String
    var done: Bool
    var createdAt: Date
    var updatedAt: Date
}

// MARK: - Trackers (daily life routines)

func dayString(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
}

func dateFromDay(_ s: String) -> Date? {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f.date(from: s)
}

func colorForTrackerName(_ name: String) -> Color {
    switch name {
    case "red": return .red
    case "green": return .green
    case "orange": return .orange
    case "yellow": return .yellow
    case "teal": return .teal
    case "purple": return .purple
    case "pink": return .pink
    case "indigo": return .indigo
    case "gray": return .gray
    default: return .blue
    }
}

let trackerColorNames = ["blue", "indigo", "purple", "pink", "red", "orange", "yellow", "green", "teal", "gray"]

struct Tracker: Identifiable, Equatable {
    let id: Int
    var name: String
    var icon: String
    var colorName: String
    var category: String
    var isCounter: Bool
    var target: Int
    var scheduleNote: String
    var isPreset: Bool
    var enabled: Bool
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    var color: Color { colorForTrackerName(colorName) }
}

struct TrackerEntry: Identifiable, Equatable {
    let id: Int
    var trackerId: Int
    var day: String
    var count: Int
    var note: String
}

struct TrackerPreset {
    let name: String
    let icon: String
    let color: String
    let category: String
    let isCounter: Bool
    let target: Int
    let scheduleNote: String

    static let all: [TrackerPreset] = [
        // Namaz
        TrackerPreset(name: "Fajr", icon: "sunrise", color: "indigo", category: "Namaz", isCounter: false, target: 1, scheduleNote: "Pray 5 times daily"),
        TrackerPreset(name: "Dhuhr", icon: "sun.max", color: "yellow", category: "Namaz", isCounter: false, target: 1, scheduleNote: "Pray 5 times daily"),
        TrackerPreset(name: "Asr", icon: "sun.horizon", color: "orange", category: "Namaz", isCounter: false, target: 1, scheduleNote: "Pray 5 times daily"),
        TrackerPreset(name: "Maghrib", icon: "sunset", color: "red", category: "Namaz", isCounter: false, target: 1, scheduleNote: "Pray 5 times daily"),
        TrackerPreset(name: "Isha", icon: "moon.stars", color: "purple", category: "Namaz", isCounter: false, target: 1, scheduleNote: "Pray 5 times daily"),
        // Quran
        TrackerPreset(name: "Quran — listen 1 para", icon: "book", color: "green", category: "Quran", isCounter: false, target: 1, scheduleNote: "One para (juz) a day"),
        // Zikr
        TrackerPreset(name: "Zikr — morning", icon: "sunrise", color: "teal", category: "Zikr", isCounter: false, target: 1, scheduleNote: "Morning adhkar"),
        TrackerPreset(name: "Zikr — evening", icon: "moon.stars", color: "indigo", category: "Zikr", isCounter: false, target: 1, scheduleNote: "Evening adhkar"),
        TrackerPreset(name: "Darood — 1000", icon: "sparkles", color: "green", category: "Zikr", isCounter: true, target: 1000, scheduleNote: "1000 darood"),
        TrackerPreset(name: "Astaghfar — 1000", icon: "drop.fill", color: "blue", category: "Zikr", isCounter: true, target: 1000, scheduleNote: "1000 astaghfar"),
        // Dua
        TrackerPreset(name: "Dua", icon: "hands.sparkles", color: "purple", category: "Dua", isCounter: false, target: 1, scheduleNote: "Make dua"),
        // Fasting
        TrackerPreset(name: "Fasting", icon: "moon.fill", color: "teal", category: "Fasting", isCounter: false, target: 1, scheduleNote: "Ramadan + every Thursday"),
        // Masjid / Jamaat
        TrackerPreset(name: "Jamaat", icon: "building.columns", color: "blue", category: "Masjid", isCounter: false, target: 1, scheduleNote: "3/month · 40/year · Sunday night"),
        TrackerPreset(name: "Masjid — attend", icon: "building.columns.fill", color: "indigo", category: "Masjid", isCounter: false, target: 1, scheduleNote: "Attend masjid"),
        // Family
        TrackerPreset(name: "Wife — time spent", icon: "heart", color: "pink", category: "Family", isCounter: false, target: 1, scheduleNote: "Quality time"),
        TrackerPreset(name: "Wife — listen", icon: "ear", color: "red", category: "Family", isCounter: false, target: 1, scheduleNote: "Really listen"),
        TrackerPreset(name: "Wife — help at home", icon: "house", color: "orange", category: "Family", isCounter: false, target: 1, scheduleNote: "Help around the house"),
        // Parents
        TrackerPreset(name: "Parents — listen", icon: "ear.fill", color: "teal", category: "Parents", isCounter: false, target: 1, scheduleNote: "Listen to them"),
        TrackerPreset(name: "Parents — talk", icon: "phone", color: "green", category: "Parents", isCounter: false, target: 1, scheduleNote: "Call / visit"),
        // Relatives
        TrackerPreset(name: "Relatives", icon: "figure.2", color: "blue", category: "Relatives", isCounter: false, target: 1, scheduleNote: "Keep in touch"),
        // Parenting
        TrackerPreset(name: "Parenting — teach language", icon: "textformat", color: "indigo", category: "Parenting", isCounter: false, target: 1, scheduleNote: "Teach language"),
        TrackerPreset(name: "Parenting — remind namaz", icon: "clock", color: "green", category: "Parenting", isCounter: false, target: 1, scheduleNote: "Remind namaz"),
        TrackerPreset(name: "Parenting — health", icon: "heart.circle", color: "pink", category: "Parenting", isCounter: false, target: 1, scheduleNote: "Health & routine"),
        // Friends
        TrackerPreset(name: "Friend — muslim", icon: "person.2", color: "green", category: "Friends", isCounter: false, target: 1, scheduleNote: "Stay in touch"),
        TrackerPreset(name: "Friend — tech", icon: "laptopcomputer", color: "blue", category: "Friends", isCounter: false, target: 1, scheduleNote: "Tech circle"),
        TrackerPreset(name: "Friend — business", icon: "briefcase", color: "purple", category: "Friends", isCounter: false, target: 1, scheduleNote: "Business circle"),
        // Health
        TrackerPreset(name: "Health — steps", icon: "shoeprints.fill", color: "orange", category: "Health", isCounter: true, target: 10000, scheduleNote: "10,000 steps"),
        TrackerPreset(name: "Health — diet", icon: "fork.knife", color: "red", category: "Health", isCounter: false, target: 1, scheduleNote: "Eat clean"),
        // Business
        TrackerPreset(name: "Business — app build", icon: "hammer", color: "indigo", category: "Business", isCounter: false, target: 1, scheduleNote: "Ship / build"),
        TrackerPreset(name: "Business — content", icon: "megaphone", color: "pink", category: "Business", isCounter: false, target: 1, scheduleNote: "Post / create"),
        TrackerPreset(name: "Business — sales", icon: "chart.line.uptrend", color: "green", category: "Business", isCounter: false, target: 1, scheduleNote: "Reach out / close"),
        TrackerPreset(name: "Business — automation", icon: "gearshape.2", color: "teal", category: "Business", isCounter: false, target: 1, scheduleNote: "Automate"),
    ]
}
