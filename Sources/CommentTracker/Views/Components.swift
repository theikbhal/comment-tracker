import SwiftUI

func formatElapsed(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    }
    return String(format: "%02d:%02d", m, s)
}

func formatDuration(_ interval: TimeInterval) -> String {
    let total = Int(interval)
    let h = total / 3600
    let m = (total % 3600) / 60
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m"
}

func formatHours(_ interval: TimeInterval) -> String {
    let hours = interval / 3600
    if hours < 1 {
        return "\(Int(interval / 60))m"
    }
    return String(format: "%.1fh", hours)
}

struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(
                    AngularGradient(
                        colors: [.blue, .purple, .pink],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)
            VStack(spacing: 2) {
                Text("\(Int((progress * 100).rounded()))%")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("of daily goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PlatformCard: View {
    let platform: Platform
    let count: Int
    let goal: Int
    var isFocus: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: platform.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(platform.color.gradient, in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 6) {
                        Text(platform.displayName)
                            .font(.headline)
                        if isFocus {
                            Label("FOCUS", systemImage: "scope")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(platform.color, in: Capsule())
                        }
                    }
                    Text(platform.handle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(platform.tier)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }
            HStack(alignment: .firstTextBaseline) {
                Text("\(count)")
                    .font(.system(size: isFocus ? 40 : 30, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                Text("/ \(goal)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(count), total: Double(max(1, goal)))
                .tint(platform.color)
        }
        .padding(isFocus ? 18 : 14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(platform.color.opacity(isFocus ? 0.5 : 0.0), lineWidth: isFocus ? 1.5 : 1)
        )
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .font(.system(size: 15, weight: .semibold))
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
    }
}
