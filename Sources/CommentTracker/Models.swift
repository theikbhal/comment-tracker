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
