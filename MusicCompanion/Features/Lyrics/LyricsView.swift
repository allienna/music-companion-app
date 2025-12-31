import SwiftUI

struct LyricsView: View {
    @ObservedObject var viewModel: LyricsViewModel

    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .opacity(0.3)

            // Lyrics content
            if viewModel.isLoading {
                loadingView
            } else if let lyrics = viewModel.lyrics {
                lyricsContentView(lyrics)
            } else if viewModel.hasError {
                errorView
            } else {
                emptyView
            }
        }
        .frame(minWidth: 300, minHeight: 400)
        .background(.ultraThinMaterial)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Album art
            if let artworkData = viewModel.currentTrack?.artworkData,
               let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.quaternary)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: "music.note")
                            .foregroundStyle(.secondary)
                    }
            }

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentTrack?.title ?? "No Track")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(viewModel.currentTrack?.artist ?? "—")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Refresh button
            Button(action: viewModel.refreshLyrics) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Refresh lyrics")
        }
    }

    // MARK: - Lyrics Content

    private func lyricsContentView(_ lyrics: Lyrics) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(Array(lyrics.lines.enumerated()), id: \.element.id) { index, line in
                        lyricsLineView(line, index: index, isCurrent: index == viewModel.currentLineIndex)
                            .id(index)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: viewModel.currentLineIndex) { _, newIndex in
                if let index = newIndex {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
    }

    private func lyricsLineView(_ line: LyricsLine, index: Int, isCurrent: Bool) -> some View {
        Text(line.text)
            .font(.system(size: isCurrent ? 18 : 15, weight: isCurrent ? .bold : .medium))
            .foregroundStyle(isCurrent ? .primary : .secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .opacity(opacityForLine(at: index))
            .animation(.easeInOut(duration: 0.2), value: isCurrent)
    }

    private func opacityForLine(at index: Int) -> Double {
        guard let currentIndex = viewModel.currentLineIndex else {
            return 0.6
        }

        let distance = abs(index - currentIndex)
        switch distance {
        case 0: return 1.0
        case 1: return 0.7
        case 2: return 0.5
        default: return 0.3
        }
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Searching for lyrics...")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("Lyrics not found")
                .font(.system(size: 14, weight: .medium))

            Text("Try a different song or check your connection")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                viewModel.refreshLyrics()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("No lyrics to display")
                .font(.system(size: 14, weight: .medium))

            Text("Play a song to see its lyrics")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    LyricsView(viewModel: LyricsViewModel())
        .frame(width: 320, height: 500)
}
