import SwiftUI
import AppKit

private let failsPageSize = 15

private func failTimeAgo(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    if interval < 60 { return "now" }
    if interval < 3600 { return "\(Int(interval / 60))m" }
    if interval < 86400 { return "\(Int(interval / 3600))h" }
    if interval < 7 * 86400 { return "\(Int(interval / 86400))d" }
    return date.formatted(date: .numeric, time: .omitted)
}

struct FailsView: View {
    @EnvironmentObject var store: Store
    @State private var draft = ""
    @State private var searchText = ""
    @State private var onlyBookmarked = false
    @State private var loaded = failsPageSize

    private var allFails: [Fail] {
        var list = store.fails
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            list = list.filter { store.fail($0, matches: searchText) }
        }
        if onlyBookmarked {
            list = list.filter(\.bookmarked)
        }
        return list
    }

    private var shownFails: [Fail] { Array(allFails.prefix(loaded)) }

    private var canLoadMore: Bool { loaded < allFails.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    composeBox
                    ForEach(shownFails) { fail in
                        FailCardView(fail: fail)
                    }
                    if allFails.isEmpty {
                        emptyState
                    } else if canLoadMore {
                        Button {
                            loaded += failsPageSize
                        } label: {
                            Text("Show older fails")
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
                Text("Fails")
                    .font(.title.bold())
                Text("\(store.fails.count) things that didn't stick")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            Button {
                onlyBookmarked.toggle()
                loaded = failsPageSize
            } label: {
                Label("Bookmarked", systemImage: onlyBookmarked ? "bookmark.fill" : "bookmark")
            }
            .buttonStyle(.bordered)
            .foregroundStyle(onlyBookmarked ? .yellow : .secondary)
            .help("Show only bookmarked fails")
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search fails…", text: $searchText)
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
                Image(systemName: "xmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.red.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    TextEditor(text: $draft)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 54)
                        .overlay(alignment: .topLeading) {
                            if draft.isEmpty {
                                Text("Hit something that didn't work? Log it — it counts as a lesson…")
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
                            store.addFail(text: draft)
                            draft = ""
                        } label: {
                            Label("Log the fail", systemImage: "xmark.app.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
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
            Image(systemName: "xmark.seal")
                .font(.system(size: 30))
                .foregroundStyle(.tertiary)
            Text(onlyBookmarked ? "No bookmarked fails yet" : "No fails logged — a clean record, or you're due for your next lesson above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Fail Card

struct FailCardView: View {
    @EnvironmentObject var store: Store
    let fail: Fail

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "xmark.seal.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.red.gradient, in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Fail")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.red)
                        Text(failTimeAgo(fail.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(fail.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            HStack(spacing: 12) {
                Text(fail.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    store.toggleFailBookmark(fail.id)
                } label: {
                    Image(systemName: fail.bookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                        .foregroundStyle(fail.bookmarked ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
                .help(fail.bookmarked ? "Remove bookmark" : "Bookmark this fail")
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(fail.bookmarked ? Color.yellow.opacity(0.5) : Color.gray.opacity(0.16), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .contextMenu {
            Button(role: .destructive) {
                store.deleteFail(fail.id)
            } label: {
                Label("Delete fail", systemImage: "trash")
            }
        }
    }
}