import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct YTDownloaderView: View {
    @EnvironmentObject var store: Store
    @State private var url = ""
    @State private var outputDir = "~/Downloads/CommentTracker"
    @State private var showDirPicker = false
    @State private var options = YTDownloadOptions()
    @State private var searchText = ""

    private var downloads: [YTDownload] {
        var list = store.sortedYTDownloads
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            list = list.filter { store.ytDownload($0, matches: q) }
        }
        return list
    }

    private var canStart: Bool {
        !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            inputCard
            Divider()
            historyHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if downloads.isEmpty {
                        Text("No downloads yet. Paste a YouTube link above and choose what to save.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 24)
                    }
                    ForEach(downloads) { d in
                        YTDownloadRow(download: d) {
                            store.cancelYTDownload(d.id)
                        } onDelete: {
                            store.deleteYTDownload(d.id)
                        } onReveal: {
                            store.revealYTDownload(d)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 760, alignment: .center)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("YouTube Downloader")
                    .font(.title.bold())
                Text("\(store.ytDownloads.filter(\.isFinished).count) saved locally")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(16)
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Paste a YouTube / video URL…", text: $url)
                .textFieldStyle(.roundedBorder)
                .onSubmit { start() }

            VStack(alignment: .leading, spacing: 8) {
                Text("What to save")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 14) {
                    Toggle("Video (mp4)", isOn: $options.includeVideo)
                    Toggle("Audio (mp3)", isOn: $options.includeAudio)
                    Toggle("Captions", isOn: $options.includeCaptions)
                    Toggle("Description", isOn: $options.includeDescription)
                    Toggle("Comments", isOn: $options.includeComments)
                }
                .toggleStyle(.checkbox)
                .font(.caption)
            }

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .foregroundStyle(.secondary)
                    TextField("Save to:", text: $outputDir)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                )
                Button {
                    showDirPicker = true
                } label: {
                    Label("Choose…", systemImage: "folder.badge.gearshape")
                }
                Spacer()
                Button {
                    start()
                } label: {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canStart)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .padding(16)
        .fileImporter(isPresented: $showDirPicker, allowedContentTypes: [.folder]) { result in
            if case .success(let url) = result {
                outputDir = url.path
            }
        }
    }

    private var historyHeader: some View {
        HStack {
            Text("Downloads")
                .font(.headline)
            Spacer()
            if !searchText.isEmpty || !downloads.isEmpty {
                searchField
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search…", text: $searchText)
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
        .padding(.vertical, 5)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 8))
        .frame(width: 180)
    }

    private func start() {
        store.startYTDownload(url: url, options: options, outputDir: outputDir)
        url = ""
    }
}

// MARK: - Row

struct YTDownloadRow: View {
    let download: YTDownload
    let onCancel: () -> Void
    let onDelete: () -> Void
    let onReveal: () -> Void

    private var statusColor: Color {
        switch download.status {
        case "downloading": return .orange
        case "done": return .green
        case "failed": return .red
        default: return .secondary
        }
    }

    private var statusSymbol: String {
        switch download.status {
        case "downloading": return "arrow.down.circle"
        case "done": return "checkmark.circle.fill"
        case "failed": return "xmark.circle.fill"
        default: return "clock"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusSymbol)
                    .font(.system(size: 18))
                    .foregroundStyle(statusColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(download.title.isEmpty ? shortURL : download.title)
                        .font(.subheadline.weight(.bold))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(download.mode)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                        Text(download.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .monospacedDigit()
                        if download.status == "failed" && !download.error.isEmpty {
                            Text(download.error)
                                .font(.caption2)
                                .foregroundStyle(.red)
                                .lineLimit(1)
                        }
                    }
                    if download.status == "downloading" {
                        ProgressView(value: download.progress)
                            .progressViewStyle(.linear)
                    }
                }
                Spacer()
                if download.status == "downloading" {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.orange)
                    }
                    .buttonStyle(.borderless)
                    .help("Cancel download")
                } else {
                    Button {
                        onReveal()
                    } label: {
                        Image(systemName: "folder")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.borderless)
                    .help("Show in Finder")
                }
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Remove from history")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.14), lineWidth: 1)
        )
        .contextMenu {
            if download.status != "downloading" {
                Button(action: onReveal) {
                    Label("Show in Finder", systemImage: "folder")
                }
            }
            Divider()
            Button(role: .destructive, action: onDelete) {
                Label("Remove from history", systemImage: "trash")
            }
        }
    }

    private var shortURL: String {
        let trimmed = download.url
        guard trimmed.count > 60 else { return trimmed }
        return String(trimmed.prefix(57)) + "…"
    }
}
