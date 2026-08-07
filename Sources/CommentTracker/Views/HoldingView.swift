import SwiftUI
import AppKit

private let holdingPageSize = 15

private func holdingTimeAgo(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "now" }
    if interval < 3600 { return "\(Int(interval / 60))m" }
    if interval < 86400 { return "\(Int(interval / 3600))h" }
    if interval < 7 * 86400 { return "\(Int(interval / 86400))d" }
    return date.formatted(date: .numeric, time: .omitted)
}

struct HoldingView: View {
    @EnvironmentObject var store: Store
    @State private var draft = ""
    @State private var searchText = ""
    @State private var onlyBookmarked = false
    @State private var onlyOpen = false
    @State private var loaded = holdingPageSize

    private var allItems: [HoldingItem] {
        var list = store.holding
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { store.holdingItem($0, matches: searchText) }
        }
        if onlyBookmarked {
            list = list.filter(\.bookmarked)
        }
        if onlyOpen {
            list = list.filter { !$0.done }
        }
        return list
    }

    private var shown: [HoldingItem] { Array(allItems.prefix(loaded)) }
    private var canLoadMore: Bool { loaded < allItems.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    composeBox
                    ForEach(shown) { item in
                        HoldingCardView(item: item)
                    }
                    if allItems.isEmpty {
                        emptyState
                    } else if canLoadMore {
                        Button {
                            loaded += holdingPageSize
                        } label: {
                            Text("Show older items")
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
                Text("Holding Hand")
                    .font(.title.bold())
                Text("\(store.holding.count) held · \(store.holding.filter { !$0.done }.count) open")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                onlyOpen.toggle()
                loaded = holdingPageSize
            } label: {
                Label("Open only", systemImage: "circle.dotted")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(onlyOpen ? .green : .secondary)
            Button {
                onlyBookmarked.toggle()
                loaded = holdingPageSize
            } label: {
                Label("Bookmarked", systemImage: onlyBookmarked ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(onlyBookmarked ? .yellow : .secondary)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search holding…", text: $searchText)
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
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.teal.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 54)
                        .overlay(alignment: .topLeading) {
                            if draft.isEmpty {
                                Text("Something you don't want to lose? Hold it here…")
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
                            store.addHolding(text: draft)
                            draft = ""
                        } label: {
                            Label("Hold it", systemImage: "hand.raised.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.teal)
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
            Image(systemName: "hand.raised")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(onlyBookmarked ? "No bookmarked items yet" : "Nothing being held — park something above to keep it safe")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Card

struct HoldingCardView: View {
    @EnvironmentObject var store: Store
    let item: HoldingItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: item.done ? "hand.point.down.fill" : "hand.raised.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background((item.done ? Color.gray : Color.teal).gradient, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(item.done ? "Held & released" : "Held")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(item.done ? Color.secondary : Color.teal)
                        Text(holdingTimeAgo(item.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(item.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .strikethrough(item.done, color: .secondary)
                        .opacity(item.done ? 0.6 : 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack(spacing: 12) {
                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    store.toggleHoldingDone(item.id)
                } label: {
                    Label(item.done ? "Reopen" : "Release", systemImage: item.done ? "arrow.uturn.backward.circle" : "hand.point.down.circle")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(item.done ? Color.secondary : Color.green)
                .font(.caption)
                .help(item.done ? "Reopen this item" : "Mark as handled / released")
                Button {
                    store.toggleHoldingBookmark(item.id)
                } label: {
                    Image(systemName: item.bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                        .foregroundStyle(item.bookmarked ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(item.bookmarked ? "Remove bookmark" : "Bookmark")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(item.bookmarked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button {
                store.toggleHoldingDone(item.id)
            } label: {
                Label(item.done ? "Reopen" : "Release (done)", systemImage: "hand.point.down")
            }
            Button(role: .destructive) {
                store.deleteHolding(item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}