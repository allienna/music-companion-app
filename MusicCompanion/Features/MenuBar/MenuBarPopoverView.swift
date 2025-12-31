import SwiftUI

struct MenuBarPopoverView: View {
    @Environment(\.openSettings) private var openSettings
    @StateObject private var viewModel = MenuBarViewModel()

    var body: some View {
        VStack(spacing: 16) {
            // Album Art
            albumArtView

            // Track Info
            trackInfoView

            // Playback Controls
            playbackControlsView

            // Progress Bar
            progressView

            Spacer()

            // Quick Actions
            quickActionsView
        }
        .padding()
        .frame(width: 300, height: 380)
    }

    // MARK: - Subviews

    private var albumArtView: some View {
        Group {
            if let artworkData = viewModel.currentTrack?.artworkData,
               let nsImage = NSImage(data: artworkData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(width: 180, height: 180)
                    .overlay {
                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                    }
            }
        }
    }

    private var trackInfoView: some View {
        VStack(spacing: 4) {
            Text(viewModel.currentTrack?.title ?? "Not Playing")
                .font(.headline)
                .lineLimit(1)

            Text(viewModel.currentTrack?.artist ?? "—")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let album = viewModel.currentTrack?.album {
                Text(album)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
    }

    private var playbackControlsView: some View {
        HStack(spacing: 32) {
            Button(action: viewModel.previousTrack) {
                Image(systemName: "backward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Button(action: viewModel.togglePlayPause) {
                Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
            }
            .buttonStyle(.plain)

            Button(action: viewModel.nextTrack) {
                Image(systemName: "forward.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
    }

    private var progressView: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary)
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * viewModel.progress, height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                Text(viewModel.elapsedTimeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()

                Spacer()

                Text(viewModel.remainingTimeString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var quickActionsView: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "heart")
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: { openSettings() }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.secondary)
    }
}

#Preview {
    MenuBarPopoverView()
        .frame(width: 320, height: 400)
}
