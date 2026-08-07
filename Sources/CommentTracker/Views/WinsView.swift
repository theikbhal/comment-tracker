import SwiftUI
import AppKit

private let winsPageSize = 15

private func winTimeAgo(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "now" }
    if interval < 3600 { return "\(Int(interval / 60))m" }
    if interval < 86400 { return "\(Int(interval / 3600))h" }
    if interval < 7 * 86400 { return "\(Int(interval / 86400))d" }
    return date.formatted(date: .numeric, time: .omitted)
}

struct WinsView: View {
    @EnvironmentObject var store: Store
    @State private var draft = ""
    @State private var searchText = ""
    @State private var onlyBookmarked = false
    @State private var loaded = winsPageSize

    private var allWins: [Win] {
        var list = store.wins
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { store.win($0, matches: searchText) }
        }
        if onlyBookmarked {
            list = list.filter(\.bookmarked)
        }
        return list
    }

    private var shownWins: [Win] { Array(allWins.prefix(loaded)) }

    private var canLoadMore: Bool { loaded < allWins.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    composeBox
                    ForEach(shownWins) { win in
                        WinCardView(win: win)
                    }
                    if allWins.isEmpty {
                        emptyState
                    } else if canLoadMore {
                        Button {
                            loaded += winsPageSize
                        } label: {
                            Text("Show older wins")
                                .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .padding(10)
                        .padding(.horizontal, 16)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20)
                .frame(maxWidth: 620, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Wins")
                    .font(.title.bold())
                Text("\(store.wins.count) wins celebrated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                onlyBookmarked.toggle()
                loaded = winsPageSize
            } label: {
                Label("Bookmarked", systemImage: onlyBookmarked ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(onlyBookmarked ? .yellow : .secondary)
            .help("Show only bookmarked wins")
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search wins…", text: $searchText)
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
                Image(systemName: "trophy.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.orange.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 54)
                        .overlay(alignment: .topLeading) {
                            if draft.isEmpty {
                                Text("Just won something? Celebrate it here…")
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
                            store.addWin(text: draft)
                            draft = ""
                        } label: {
                            Label("Celebrate", systemImage: "party.popper.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
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

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "party.popper")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(onlyBookmarked ? "No bookmarked wins yet" : "No wins yet — celebrate your first one above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Win Card

struct WinCardView: View {
    @EnvironmentObject var store: Store
    let win: Win

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.orange.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Win")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.orange)
                        Text(winTimeAgo(win.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(win.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack(spacing: 12) {
                Text(win.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    store.toggleWinBookmark(win.id)
                } label: {
                    Image(systemName: win.bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                        .foregroundStyle(win.bookmarked ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(win.bookmarked ? "Remove bookmark" : "Bookmark this win")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(win.bookmarked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button(role: .destructive) {
                store.deleteWin(win.id)
            } label: {
                Label("Delete win", systemImage: "trash")
            }
        }
    }
}