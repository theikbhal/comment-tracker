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
