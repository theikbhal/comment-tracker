import SwiftUI
import AppKit

private struct VideoCardTopKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] { [:] }
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

struct VideosView: View {
    @EnvironmentObject var store: Store
    @State private var showingAdd = false
    @State private var searchText = ""

    private var matchedCount: Int {
        store.videos.filter { store.video($0, matches: searchText) }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            VideoBoardView(searchText: searchText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .sheet(isPresented: $showingAdd) {
            AddVideoView()
                .environmentObject(store)
        }
        .sheet(item: $store.videoToDetail) { video in
            VideoDetailView(videoID: video.id)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Videos")
                    .font(.title.bold())
                Text("\(store.totalVideos) in your watch queue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            searchField
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("\(matchedCount) found")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Button {
                showingAdd = true
            } label: {
                Label("Add Video", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search videos…", text: $searchText)
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
        .frame(width: 230)
    }
}

// MARK: - Board

struct VideoBoardView: View {
    @EnvironmentObject var store: Store
    let searchText: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 14) {
                ForEach(VideoStage.allCases) { stage in
                    VideoColumnView(stage: stage, searchText: searchText)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Column

struct VideoColumnView: View {
    @EnvironmentObject var store: Store
    let stage: VideoStage
    let searchText: String

    @State private var isDropTargeted = false
    @State private var cardTops: [Int: CGFloat] = [:]

    private var columnSpaceName: String { "vidcol-\(stage.rawValue)" }
    private var videos: [Video] {
        store.videosForStage(stage).filter { store.video($0, matches: searchText) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(videos) { video in
                        VideoCardView(video: video)
                            .background(
                                GeometryReader { geo in
                                    Color.clear.preference(
                                        key: VideoCardTopKey.self,
                                        value: [video.id: geo.frame(in: .named(columnSpaceName)).minY]
                                    )
                                }
                            )
                    }
                    if videos.isEmpty {
                        emptyHint
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 232)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(stage.color.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isDropTargeted ? stage.color : Color.gray.opacity(0.14), lineWidth: isDropTargeted ? 2 : 1)
        )
        .coordinateSpace(name: columnSpaceName)
        .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers, location in
            handleDrop(providers, location: location)
        }
        .onPreferenceChange(VideoCardTopKey.self) { value in
            cardTops = value
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: stage.symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(stage.color)
                Text(stage.displayName)
                    .font(.headline)
                Spacer()
                Text("\(videos.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(stage == .holding ? "Queue" : "Watch")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
        .padding(.horizontal, 4)
    }

    private var emptyHint: some View {
        VStack(spacing: 6) {
            Image(systemName: stage.symbol)
                .font(.system(size: 22))
                .foregroundStyle(.tertiary)
            Text("Drag videos here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .contentShape(Rectangle())
    }

    private func handleDrop(_ providers: [NSItemProvider], location: CGPoint) -> Bool {
        guard let provider = providers.first else { return false }
        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let idString = object as? String, let id = Int(idString) else { return }
            Task { @MainActor in
                let index = self.insertionIndex(for: location.y)
                self.store.moveVideo(id, to: stage, at: index)
            }
        }
        return true
    }

    private func insertionIndex(for locationY: CGFloat) -> Int {
        var index = videos.count
        for (i, v) in videos.enumerated() {
            if let top = cardTops[v.id], top > locationY {
                index = i
                break
            }
        }
        return index
    }
}

// MARK: - Card

struct VideoCardView: View {
    @EnvironmentObject var store: Store
    let video: Video

    private var videoComments: [VideoComment] { store.videoComments(for: video.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: video.platform.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(video.platform.color.gradient, in: RoundedRectangle(cornerRadius: 7))
                Text(video.title)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            if !video.note.isEmpty {
                Text(video.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            HStack(spacing: 8) {
                if !video.url.isEmpty {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                if videoComments.count > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 9))
                        Text("\(videoComments.count)")
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Text(video.updatedAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(video.stage.color)
                .frame(width: 3)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 3, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .onTapGesture(count: 2) {
            store.videoToDetail = video
        }
        .onDrag {
            return NSItemProvider(object: "\(video.id)" as NSString)
        }
    }
}

// MARK: - Add Video

struct AddVideoView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var url = ""
    @State private var platform: VideoPlatform = .youtube
    @State private var stage: VideoStage = .holding

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Video")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 6) {
                Text("Platform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Platform", selection: $platform) {
                    ForEach(VideoPlatform.allCases) { p in
                        Label(p.displayName, systemImage: p.symbol).tag(p)
                    }
                }
                .pickerStyle(.segmented)
            }

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Video link — youtube, x, instagram reel…", text: $url)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("List")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("List", selection: $stage) {
                    ForEach(VideoStage.allCases) { s in
                        Text(s.displayName).tag(s)
                    }
                }
                .labelsHidden()
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button {
                    store.addVideo(title: title, url: url, platform: platform, stage: stage)
                    dismiss()
                } label: {
                    Label("Add", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 440)
    }
}
